
#define LIB_NAME "ProjectPath"
#define MODULE_NAME "project_path"

#include <dmsdk/sdk.h>

#if defined(_WIN32) || defined(_WIN64)
// Windows
#include <direct.h>
#include <limits.h>
#define GetCWD _getcwd
#ifndef PATH_MAX
#define PATH_MAX _MAX_PATH
#endif
#elif defined(__APPLE__) && defined(__MACH__)
// macOS
#include <unistd.h>
#include <sys/param.h>
#include <limits.h>
#include <errno.h>
#define GetCWD getcwd
#ifndef PATH_MAX
#define PATH_MAX MAXPATHLEN
#endif
#else
// Linux
#include <unistd.h>
#include <errno.h>
#if defined(__linux__)
#include <linux/limits.h>
#else
#include <limits.h>
#endif
#define GetCWD getcwd
// Fallback PATH_MAX
#ifndef PATH_MAX
#define PATH_MAX 4096
#endif
#endif

#include <string.h>

static int GetProjectRoot(lua_State* L)
{
    char path[PATH_MAX];
    if (GetCWD(path, sizeof(path)) == NULL)
    {
        // GetCWD failed - provide diagnostic information
        const char* error_msg = "Failed to get current working directory";

#if !defined(_WIN32) && !defined(_WIN64)
        // On Unix-like systems, check errno for specific error
        if (errno == EACCES)
        {
            error_msg = "Permission denied: cannot read current working directory";
            dmLogError("GetProjectRoot: %s (errno: EACCES)", error_msg);
        }
        else if (errno == ENOENT)
        {
            error_msg = "Current working directory has been unlinked";
            dmLogError("GetProjectRoot: %s (errno: ENOENT)", error_msg);
        }
        else
        {
            dmLogError("GetProjectRoot: getcwd failed with errno: %d", errno);
        }
#else
        dmLogError("GetProjectRoot: _getcwd failed");
#endif

        lua_pushnil(L);
        lua_pushstring(L, error_msg);
        return 2; // Return nil and error message
    }

    // Normalize Windows backslashes to forward slashes
#if defined(_WIN32) || defined(_WIN64)
    for (char* p = path; *p; ++p)
    {
        if (*p == '\\')
        {
            *p = '/';
        }
    }
#endif

    // Remove trailing slash
    size_t len = strlen(path);
    if (len > 0 && path[len - 1] == '/')
    {
        path[len - 1] = '\0';
    }

    // If the last directory is "build", remove it
    char* last_slash = strrchr(path, '/');
    if (last_slash)
    {
        const char* last_dir = last_slash + 1;
        if (strcmp(last_dir, "build") == 0)
        {
            *last_slash = '\0';
        }
    }

    lua_pushstring(L, path);
    return 1;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] = { { "get", GetProjectRoot }, { 0, 0 } };

static void           LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result InitializeProjectPath(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    dmLogInfo("Registered %s Extension", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

DM_DECLARE_EXTENSION(ProjectPath, LIB_NAME, 0, 0, InitializeProjectPath, 0, 0, 0)
