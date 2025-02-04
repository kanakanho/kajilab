Stack dump: 0. Program arguments: /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-frontend -frontend -interpret main.swift -Xllvm -aarch64-use-tbi -enable-objc-interop -stack-check -sdk /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.0.sdk -color-diagnostics -new-driver-path /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift-driver -empty-abi-descriptor -resource-dir /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift -module-name main -disable-clang-spi -target-sdk-version 15.0 -target-sdk-name macosx15.0 -external-plugin-path /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins#/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server -external-plugin-path /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/local/lib/swift/host/plugins#/Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/bin/swift-plugin-server -plugin-path /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/host/plugins -plugin-path /Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/local/lib/swift/host/plugins

1.       Apple Swift version 6.0 (swiftlang-6.0.0.9.10 clang-1600.0.26.2)
2.       Compiling with effective version 5.10
3.       While running user code "main.swift"
    Stack dump without symbol names (ensure you have llvm-symbolizer in your PATH or set the environment var `LLVM_SYMBOLIZER_PATH` to point to it):
    0 swift-frontend 0x0000000105c6f0fc llvm::sys::PrintStackTrace(llvm::raw_ostream&, int) + 56
    1 swift-frontend 0x0000000105c6d350 llvm::sys::RunSignalHandlers() + 112
    2 swift-frontend 0x0000000105c6f6c8 SignalHandler(int) + 292
    3 libsystem_platform.dylib 0x000000019def2584 \_sigtramp + 56
    4 libsystem_platform.dylib 0x000000010baa0498 \_sigtramp + 18446744071255547724
    5 libsystem_platform.dylib 0x000000010baa01d4 \_sigtramp + 18446744071255547016
    6 swift-frontend 0x0000000100768c20 llvm::orc::runAsMain(int (_)(int, char\*\*), llvm::ArrayRef<std::**1::basic_string<char, std::**1::char_traits<char>, std::**1::allocator<char>>>, std::**1::optional<llvm::StringRef>) + 1940
    7 swift-frontend 0x000000010067c5f4 swift::SwiftJIT::runMain(llvm::ArrayRef<std::**1::basic_string<char, std::**1::char_traits<char>, std::**1::allocator<char>>>) + 172
    8 swift-frontend 0x000000010068a000 swift::RunImmediately(swift::CompilerInstance&, std::**1::vector<std::**1::basic_string<char, std::**1::char_traits<char>, std::**1::allocator<char>>, std::**1::allocator<std::**1::basic_string<char, std::**1::char_traits<char>, std::**1::allocator<char>>>> const&, swift::IRGenOptions const&, swift::SILOptions const&, std::**1::unique_ptr<swift::SILModule, std::**1::default_delete<swift::SILModule>>&&) + 1028
    9 swift-frontend 0x000000010061e59c processCommandLineAndRunImmediately(swift::CompilerInstance&, std::**1::unique_ptr<swift::SILModule, std::\_\_1::default_delete<swift::SILModule>>&&, llvm::PointerUnion<swift::ModuleDecl_, swift::SourceFile*>, swift::FrontendObserver*, int&) + 536
    10 swift-frontend 0x000000010061a004 performCompileStepsPostSILGen(swift::CompilerInstance&, std::**1::unique_ptr<swift::SILModule, std::**1::default_delete<swift::SILModule>>, llvm::PointerUnion<swift::ModuleDecl*, swift::SourceFile*>, swift::PrimarySpecificPaths const&, int&, swift::FrontendObserver*) + 2044
    11 swift-frontend 0x00000001006196e4 swift::performCompileStepsPostSema(swift::CompilerInstance&, int&, swift::FrontendObserver*) + 2888
    12 swift-frontend 0x000000010061c714 performCompile(swift::CompilerInstance&, int&, swift::FrontendObserver*) + 2940
    13 swift-frontend 0x000000010061af58 swift::performFrontend(llvm::ArrayRef<char const*>, char const*, void*, swift::FrontendObserver\*) + 3572
    14 swift-frontend 0x00000001005a201c swift::mainEntry(int, char const\*\*) + 3680
    15 dyld 0x000000019db37154 start + 2476
