# Flutter Rust FFI Template

This project is a Flutter Plugin template. 

It provides out-of-the box support for cross-compiling native Rust code for all available iOS and Android architectures and call it from plain Dart using [Foreign Function Interface](https://en.wikipedia.org/wiki/Foreign_function_interface).

This template provides first class FFI support, **the clean way**. 
- No Swift/Kotlin wrappers
- No message passing
- No async/await on Dart
- Write once, use everywhere
- No garbage collection
- Mostly automated development
- No need to export `aar` bundles or `.framework`'s

## Getting started

### Write your native code

Edit your code within `rust/src/lib.rs` and add any dependencies you need.

Make sure to annotate your exported functions with `#[no_mangle]` and `pub extern` so the function names can be matched from Dart.

Returning strings or structs may require using `unsafe` blocks. Returned strings or structs will need to be `free`'d from Dart.

### Compile the library

- Make sure that the Android NDK is installed
  - You might also need LLVM from the SDK manager
- Ensure that the env variable `$ANDROID_NDK_HOME` points to the NDK base folder
  - It may look like `/Users/brickpop/Library/Android/sdk/ndk-bundle` on MacOS
  - And look like `/home/brickpop/dev/android/ndk-bundle` on Linux
- On the `rust` folder:
  - Run `make` to see the available actions
  - Run `make init` to install the Rust targets
  - Run `make all` to build the libraries and the `.h` file
- Update the name of your library in `Cargo.toml`
  - You'll need to update the symlinks to target the new file names. See iOS and Android below.

Generated artifacts:
- Android libraries
  - `target/aarch64-linux-android/release/libgreet.so`
  - `target/armv7-linux-androideabi/release/libgreet.so`
  - `target/i686-linux-android/release/libgreet.so`
- iOS library
  - `target/universal/release/libgreet.a`
- Bindings header
  - `target/bindings.h`

### Reference the shared objects

#### iOS

Ensure that `ios/mylib.podspec` includes the following directives:

```diff
...
   s.source           = { :path => '.' }
+  s.public_header_files = 'Classes**/*.h'
   s.source_files = 'Classes/**/*'
+  s.static_framework = true
+  s.vendored_libraries = "**/*.a"
   s.dependency 'Flutter'
   s.platform = :ios, '8.0'
...
```

On `flutter/ios`, place a symbolic link to the `libgreet.a` file

```sh
$ cd flutter/ios
$ ln -s ../rust/target/universal/release/libgreet.a .
```

Append the generated function signatures from `rust/target/bindings.h` into `flutter/ios/Classes/MylibPlugin.h`

```sh 
$ cd flutter/ios
$ cat ../rust/target/bindings.h >> Classes/MylibPlugin.h
```

In our case, it will append `char *rust_greeting(const char *to);` and `void rust_cstr_free(char *s);`

NOTE: By default, XCode will skip bundling the `libgreet.a` library if it detects that it is not being used. To force its inclusion, add dummy invocations in `SwiftMylibPlugin.swift` that use every single native function that you use from Flutter:

```kotlin
...
  public func dummyMethodToEnforceBundling() {
    rust_greeting("...");
    compress_jpeg_file("...");
    compress_png_file("...");
    // ...
    // This code will force the bundler to use these functions, but will never be called
  }
}
```

If you won't be using Flutter channels, the rest of methods can be left empty.

> Note: Support for avmv7, armv7s and i386 is deprecated. The targets can still be compiled with Rust 1.41 or earlier and by uncommenting the `make init` line on `rust/makefile`

#### Android

Similarly as we did on iOS with `libgreet.a`, create symlinks pointing to the binary libraries on `rust/target`.

You should have the following structure on `flutter/android` for each architecture:

```
src
└── main
    └── jniLibs
        ├── arm64-v8a
        │   └── libgreet.so@ -> ../../../../../rust/target/aarch64-linux-android/release/libgreet.so
        ├── armeabi-v7a
        │   └── libgreet.so@ -> ../../../../../rust/target/armv7-linux-androideabi/release/libgreet.so
        ├── x86
        │   └── libgreet.so@ -> ../../../../../rust/target/i686-linux-android/release/libgreet.so
        └── x86_64
            └── libgreet.so@ -> ../../../../../rust/target/x86_64-linux-android/release/libgreet.so
```

As before, if you are not using Flutter channels, the methods within `android/src/main/kotlin/org/mylib/mylib/MylibPlugin.kt` can be left empty.

### Declare the bindings in Dart

In `/lib/mylib.dart`, initialize the function bindings from Dart and implement any additional logic that you need.

Load the library: 
```dart
final DynamicLibrary nativeExampleLib = Platform.isAndroid
    ? DynamicLibrary.open("libgreet.so")
    : DynamicLibrary.process();
```

Find the symbols we want to use, with the appropriate Dart signatures:
```dart
final Pointer<Utf8> Function(Pointer<Utf8>) rustGreeting = nativeExampleLib
    .lookup<NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>("rust_greeting")
    .asFunction();

final void Function(Pointer<Utf8>) freeGreeting = nativeExampleLib
    .lookup<NativeFunction<Void Function(Pointer<Utf8>)>>("rust_cstr_free")
    .asFunction();
```

Call them:
```dart
// Prepare the parameters
final name = "John Smith";
final Pointer<Utf8> namePtr = Utf8.toUtf8(name);
print("- Calling rust_greeting with argument:  $namePtr");

// Call rust_greeting
final Pointer<Utf8> resultPtr = rustGreeting(namePtr);
print("- Result pointer:  $resultPtr");

final String greetingStr = Utf8.fromUtf8(resultPtr);
print("- Response string:  $greetingStr");
```

When we are done using `greetingStr`, tell Rust to free it, since the Rust implementation kept it alive for us to use it.
```dart
freeGreeting(resultPtr);
```

## More information
- https://dart.dev/guides/libraries/c-interop
- https://flutter.dev/docs/development/platform-integration/c-interop
- https://github.com/dart-lang/samples/blob/master/ffi/structs/structs.dart
- https://mozilla.github.io/firefox-browser-architecture/experiments/2017-09-06-rust-on-ios.html
- https://mozilla.github.io/firefox-browser-architecture/experiments/2017-09-21-rust-on-android.html
