/*
 can also be compiled using
 clang -fobjc-arc $OBJCFLAGS $LDFLAGS -framework Foundation -framework Cocoa LauncherGtk3/geany/geany/main.m -o geany
 */

#import <Foundation/Foundation.h>
#include <dlfcn.h>

#define MAX_ARR_SIZE 100

static NSString *get_locale(NSString *bundle_data) {
    NSString *fallback = @"en_US.UTF-8";
    
    BOOL ignore_locale = [[NSFileManager defaultManager] fileExistsAtPath: [@"~/.config/geany/ignore_locale" stringByExpandingTildeInPath]];
    if (ignore_locale) {
        return fallback;
    }
    
    NSArray<NSString *> *langs = [NSLocale preferredLanguages];
    for (NSString *lng in langs) {
        BOOL found = NO;
        NSString *lang;
        NSArray<NSString *> *comps = [lng componentsSeparatedByString:@"-"];
        if (comps.count > 1) {
            lang = [NSString stringWithFormat:@"%@_%@", comps[0], comps[1]];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_data, lang];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        if (!found && comps.count > 0) {
            NSString *lng = comps[0];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_data, lng];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (found && comps.count == 1) {
                lang = lng;
            }
        }
        if (found) {
            return [lang stringByAppendingString:@".UTF-8"];
        }
    }

    return fallback;
}


static void export_env_array(NSDictionary<NSString *, NSString *> *dict) {
    for (NSString *key in dict) {
        setenv([key UTF8String], [dict[key] UTF8String], 1);
    }
}


static int fill_argv_array(const char *arr[], NSArray<NSString *> *array) {
    int i = 0;
    for (NSString *value in array) {
        arr[i] = [value UTF8String];
        i++;
        if (i == MAX_ARR_SIZE - 1) {
            break;
        }
    }
    arr[i] = NULL;
    return i;
}


static int run_geany() {
    NSString *bundle_dir = [[NSBundle mainBundle] bundlePath];
    
    NSString *bundle_contents = [bundle_dir stringByAppendingPathComponent: @"Contents"];
    NSString *bundle_res = [bundle_contents stringByAppendingPathComponent: @"Resources"];
    NSString *bundle_lib = [bundle_res stringByAppendingPathComponent: @"lib"];
    NSString *bundle_data = [bundle_res stringByAppendingPathComponent: @"share"];
    NSString *bundle_etc = [bundle_res stringByAppendingPathComponent: @"etc"];

    NSString *lang = get_locale(bundle_data);

    //set environment variables
    //see https://developer.gnome.org/gtk3/stable/gtk-running.html
    NSDictionary<NSString *, NSString *> *env = @{
        @"XDG_CONFIG_DIRS": bundle_etc,
        @"XDG_DATA_DIRS": bundle_data,

        @"GTK_PATH": bundle_res,
        @"GTK_EXE_PREFIX": bundle_res,
        @"GTK_DATA_PREFIX": bundle_res,
        @"GTK_IM_MODULE_FILE": [bundle_etc stringByAppendingPathComponent: @"gtk-3.0/gtk.immodules"],
        @"GDK_PIXBUF_MODULE_FILE": [bundle_lib stringByAppendingPathComponent: @"gdk-pixbuf-2.0/2.10.0/loaders.cache"],
        
        //Locale variables
        @"LANG": lang,
        @"LC_MESSAGES": lang,
        @"LC_MONETARY": lang,
        @"LC_COLLATE": lang,
        @"LC_ALL": lang,
        
        //Geany variables
        @"GEANY_PLUGINS_SHARE_PATH": [bundle_res stringByAppendingPathComponent: @"share/geany-plugins"],
        @"ENCHANT_MODULE_PATH": [bundle_lib stringByAppendingPathComponent: @"enchant"],
        @"GIO_MODULE_DIR": [bundle_lib stringByAppendingPathComponent: @"gio/modules"],
    };
    
    //set binary name and command line arguments
    NSMutableArray<NSString *> *args = [NSProcessInfo.processInfo.arguments mutableCopy];
    
    if (args.count > 1 && [args[1] hasPrefix:@"-psn_"]) {
        [args removeObjectAtIndex: 1];
    }

    [args addObject:[NSString stringWithFormat:@"--vte-lib=%@/libvte-2.91.0.dylib", bundle_lib]];
    
    //debugging
    NSString *verbose_param = @"--osx-verbose";
    if ([args containsObject: verbose_param]) {
        [args removeObject:verbose_param];
        NSLog(@"env: %@", env);
        NSLog(@"argv: %@", args);
    }
    
    export_env_array(env);

    const char *argv[MAX_ARR_SIZE];
    int argc = fill_argv_array(argv, args);
    
    /*
     We need to load libgeany dynamically - if we loaded it statically, it would have
     been loaded by now already and the environment variables above would be set
     too late (apparently they are read already when some of the libraries are loading)
     */
    int ret = 1;
    void *lib_handle = dlopen([[bundle_lib stringByAppendingPathComponent:@"libgeany.0.dylib"] UTF8String], RTLD_LAZY|RTLD_GLOBAL);
    if (lib_handle) {
        int (*main_lib)(int, char**) = dlsym(lib_handle, "main_lib");
        if (main_lib) {
            ret = main_lib(argc, (char **)argv);
        }
        else {
            NSLog(@"dlsym() failed");
        }
        dlclose(lib_handle);
    }
    else {
        NSLog(@"dlopen() failed");
    }
    
    return ret;
}


int main(int argc, const char *argv[]) {
    @autoreleasepool {
        return run_geany();
    }
}
