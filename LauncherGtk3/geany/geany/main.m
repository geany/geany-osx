/*
 can also be compiled using
 clang -fobjc-arc $OBJCFLAGS $LDFLAGS -framework Foundation -framework Cocoa LauncherGtk3/geany/geany/main.m -o geany
 */

#import <Foundation/Foundation.h>

#include <dlfcn.h>
#include <limits.h>

#define GEANY_CONFIG_DIR [@"~/.config/geany" stringByExpandingTildeInPath]
#define CONFIG_FILE [GEANY_CONFIG_DIR stringByAppendingPathComponent: @"geany_mac.conf"]

#define THEME_KEY @"theme"
#define LOCALE_KEY @"locale"
#define IM_MODULE_KEY @"im_module"


@interface ConfigValue : NSObject

@property (nonatomic, copy) NSString *value;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, assign) BOOL present;

+ (ConfigValue *) valueWithDefault:(NSString *)deflt comment:(NSString *)comment;

@end

@implementation ConfigValue

+ valueWithDefault:(NSString *)deflt comment:(NSString *)comment {
    ConfigValue *val = [[ConfigValue alloc] init];
    val.value = deflt;
    val.desc = comment;
    val.present = NO;
    return val;
}

@end


NSDictionary<NSString *, ConfigValue *> *config = nil;


static void read_config() {
    NSString *file = [NSString stringWithContentsOfFile:CONFIG_FILE encoding:NSUTF8StringEncoding error:nil];
    if (file == nil) {
        return;
    }
    NSArray<NSString *> *lines = [file componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSArray<NSString *> *key_value = [trimmed componentsSeparatedByString: @"="];
        if (key_value.count != 2) {
            continue;
        }
        NSString *key = [key_value[0] lowercaseString];
        if (config[key] != nil) {
            config[key].value = key_value[1];
            config[key].present = YES;
        }
    }
}


static BOOL write_to_file(NSString *content, NSString *path) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    NSError *err = nil;
    BOOL success = [content writeToFile:path atomically:NO encoding:NSUTF8StringEncoding
                 error:&err];
    if (!success) {
        NSLog(@"Failed to write config file into %@: %@", path, err.localizedDescription);
    }
    return success;
}


static void write_config_if_needed() {
    /* Rewrite config file if some configuration option isn't present. This way we can let
       users know about new config options possibly introduced in the future. */
    BOOL update_config = NO;
    for (NSString *key in config) {
        if (!config[key].present) {
            update_config = YES;
            break;
        }
    }
    if (!update_config) {
        return;
    }
    
    NSMutableString *configFile = [[NSMutableString alloc] init];
    [configFile appendString:@"[Settings]\n"];
    for (NSString *key in config) {
        [configFile appendFormat:@"# %@\n", config[key].desc];
        [configFile appendFormat:@"%@=%@\n", key, config[key].value];
    }

    write_to_file(configFile, CONFIG_FILE);
}


static BOOL write_gtk_config() {
    BOOL light = YES;
    NSString *theme = config[THEME_KEY].value;
    if ([theme isEqualToString:@"1"]) {
        light = YES;
    }
    else if ([theme isEqualToString:@"2"]) {
        light = NO;
    }
    else {
        NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppleInterfaceStyle"];
        if (val != nil) {
            light = [[val lowercaseString] isEqualToString:@"light"];
        }
    }

    NSString *gtk_config = [NSString stringWithFormat: @"[Settings]\n"
                            @"gtk-menu-images=1\n"
                            @"gtk-application-prefer-dark-theme=%@\n"
                            @"gtk-icon-theme-name=%@\n",
                            light ? @"0" : @"1",
                            light ? @"Papirus" : @"Papirus-Dark"];

    return write_to_file(gtk_config, [GEANY_CONFIG_DIR stringByAppendingPathComponent: @"gtk-3.0/settings.ini"]);
}


static NSString *get_locale(NSString *bundle_share) {
    if (config[LOCALE_KEY].value.length > 0) {
        return config[LOCALE_KEY].value;
    }
    
    NSArray<NSString *> *langs = [NSLocale preferredLanguages];
    for (NSString *lng in langs) {
        BOOL found = NO;
        NSString *lang;
        NSArray<NSString *> *comps = [lng componentsSeparatedByString:@"-"];
        if (comps.count > 1) {
            lang = [NSString stringWithFormat:@"%@_%@", [comps[0] lowercaseString], [comps[1] uppercaseString]];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_share, lang];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
        }
        if (!found && comps.count > 0) {
            NSString *lng = [comps[0] lowercaseString];
            NSString *path = [NSString stringWithFormat:@"%@/locale/%@", bundle_share, lng];
            found = [[NSFileManager defaultManager] fileExistsAtPath:path];
            if (found && comps.count == 1) {
                lang = lng;
            }
        }
        if (found) {
            return [lang stringByAppendingString:@".UTF-8"];
        }
    }

    return @"en_US.UTF-8";
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
        if (i == ARG_MAX - 1) {
            break;
        }
    }
    arr[i] = NULL;
    return i;
}


static int run_geany() {
    config = @{
        THEME_KEY: [ConfigValue valueWithDefault:@"0" comment:@"0: automatic selection based on system settings (requires Geany restart when changed, macOS 10.14+); 1: light; 2: dark; make sure there's no ~/.config/gtk-3.0/settings.ini file, otherwise it overrides the settings made here"],
        LOCALE_KEY: [ConfigValue valueWithDefault:@"" comment:@"no value: autodetect; locale string: locale to be used (e.g. en_US.UTF-8)"],
        IM_MODULE_KEY: [ConfigValue valueWithDefault:@"" comment:@"no value: don't use any IM module; module name: use the specified module, e.g. 'quartz' for native macOS behavior (slightly buggy so not enabled by default), for complete list of modules see Geany.app/Contents/Resources/lib/gtk-3.0/3.0.0/immodules, use without the 'im-' prefix"],
    };

    read_config();
    write_config_if_needed();
    BOOL have_gtk_config = write_gtk_config();
    
    NSString *bundle_dir = [[NSBundle mainBundle] bundlePath];
    NSString *bundle_resources = [bundle_dir stringByAppendingPathComponent: @"Contents/Resources"];
    NSString *bundle_lib = [bundle_resources stringByAppendingPathComponent: @"lib"];
    NSString *bundle_share = [bundle_resources stringByAppendingPathComponent: @"share"];
    NSString *bundle_etc = [bundle_resources stringByAppendingPathComponent: @"etc"];

    NSString *lang = get_locale(bundle_share);

    //set environment variables
    //see https://developer.gnome.org/gtk3/stable/gtk-running.html
    NSMutableDictionary<NSString *, NSString *> *env = [@{
        @"XDG_CONFIG_DIRS": have_gtk_config ? GEANY_CONFIG_DIR : bundle_etc,  /* used to locate gtk settings.ini */
        @"XDG_DATA_DIRS": bundle_share,

        @"GIO_MODULE_DIR": [bundle_lib stringByAppendingPathComponent: @"gio/modules"],

        @"GTK_PATH": bundle_resources,
        @"GTK_EXE_PREFIX": bundle_resources,
        @"GTK_DATA_PREFIX": bundle_resources,
        @"GDK_PIXBUF_MODULE_FILE": [bundle_lib stringByAppendingPathComponent: @"gdk-pixbuf-2.0/2.10.0/loaders.cache"],
        
        @"LANG": lang,
        @"LC_MESSAGES": lang,
        @"LC_MONETARY": lang,
        @"LC_COLLATE": lang,
        @"LC_ALL": lang,
        
        //TODO: replace with XDG_DATA_DIRS in Geany
        @"GEANY_PLUGINS_SHARE_PATH": [bundle_share stringByAppendingPathComponent: @"geany-plugins"],
        
        //patched in https://gitlab.gnome.org/GNOME/gtk-osx/blob/master/patches/enchant-env.patch
        @"ENCHANT_MODULE_PATH": [bundle_lib stringByAppendingPathComponent: @"enchant"],
    } mutableCopy];
    
    if (config[IM_MODULE_KEY].value.length > 0) {
        env[@"GTK_IM_MODULE"] = config[IM_MODULE_KEY].value;
        env[@"GTK_IM_MODULE_FILE"] = [bundle_lib stringByAppendingPathComponent: @"gtk-3.0/3.0.0/immodules.cache"];
    }
    else {
        //point to an invalid path so no IM module is loaded
        env[@"GTK_IM_MODULE_FILE"] = [bundle_lib stringByAppendingPathComponent: @"gtk-3.0/3.0.0/immodules.cache1"];
    }
    
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

    const char *argv[ARG_MAX];
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
        NSLog(@"dlopen() failed (possibly unsigned libgeany.0.dylib)");
    }
    
    return ret;
}


int main(int argc, const char *argv[]) {
    @autoreleasepool {
        return run_geany();
    }
}
