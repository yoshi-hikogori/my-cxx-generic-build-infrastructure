# ソース構成

ソースは役割ごとに分け、依存の向きを一方向にしています。

- `app/`：実行ファイルのエントリーポイント
- `lib/`：プラットフォームに依存しないライブラリの実装
- `modules/`：`CXX_MODULES` file setで公開するmodule interface unit
- `platform/`：OS依存の実装が必要になったときに追加するディレクトリ。現在はありません。

ソースは`CMakeLists.txt`の`target_sources()`に明示しています。公開moduleは
`MyImportStd::modules`をリンクしてからimportします。

```cpp
import my_import_std;
```

このプロジェクトではC++ moduleを必須にしています。
`MY_IMPORT_STD_ENABLE_MODULES`のオプション宣言は廃止し、`OFF`を指定するとconfigure時に
エラーになります。既存cacheの`ON`は受け入れますが、moduleを切り替える効果はありません。

## 標準ライブラリmodule

CMake 4.5.0ではC++20以降のコードで`import std;`を利用できます。Ninja Multi-Config
生成器に対応していますが、Visual Studio生成器には対応していません。
このプロジェクトはNinjaまたはNinja Multi-Configを必要とし、Visual Studioのpresetは
無効にしています。廃止された`CXX_MODULE_STD`設定は使用しません。アプリでは次のように
プロジェクトmoduleと標準ライブラリmoduleをimportします。

```cpp
import std;
import my_import_std;
```

`import std;`の利用可否はCMakeのバージョンだけでなく、コンパイラと標準ライブラリの
組み合わせにも依存します。現在のclang-cl/clang++はWindowsのMSVC STLを使用している
ため、構成やビルドでエラーになる場合は、CMake・コンパイラ・標準ライブラリの組み合わせを
確認してください。Windowsのclang-cl・clang++・MSVCではDebug/Releaseを検証しました。
Linux・Emscripten・WASIでの実ビルドは未検証です。特にSDK向けpresetは実験的な選択肢であり、
SDKのC++ module・`import std`対応を保証するものではありません。

## clangd

workspaceではclangdの`--experimental-modules-support`を有効にしています。ルートの
`.clangd`ではcompile databaseの場所を`./build`に指定し、`_CLANGD=1`を定義しています。

## CMake設定

target定義はルートに残し、共通設定と配布設定を分離しています。

案件・企画に依存せず再利用する汎用ビルド基盤の名前には`GenericBuildInfrastructure`を使います。
ディレクトリ名は`generic-build-infrastructure`、関数の接頭辞は`cmake_generic_build_infrastructure_`です。
プロジェクト固有の設定や、開発用の構成を組み合わせる`bundle:development`とは区別します。

- [汎用ビルド基盤のtarget設定](../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake)：compiler設定、成果物・PDBの出力先、静的MSVCランタイムの適用。
- [標的環境の処理](../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePlatform.cmake)：architecture・CPU水準・実行環境の検証とCPUオプションの適用。
- [計測処理](../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureInstrumentation.cmake)：CMakeの計測登録とClangのtrace設定。
- [プロジェクトtarget設定](../cmake/MyImportStdTargetSettings.cmake)：案件のCPU・architecture・計測設定を汎用関数へ渡す処理。
- [install/export・CPack設定](../cmake/MyImportStdInstall.cmake)：このプロジェクトの配布仕様。
- [toolchain](../cmake/toolchains/)：native環境のcompiler選択と、SDK付属toolchainへの委譲。

汎用ビルド基盤のtarget設定はtarget作成後に呼び出します。ローカルのcompiled targetを指すaliasも使えます。
未知の引数や値の欠落、存在しないtargetを指定した場合と、imported・interface・custom targetを
渡した場合はエラーになります。

```cmake
include("${CMAKE_CURRENT_LIST_DIR}/cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake")

cmake_generic_build_infrastructure_apply_compile_settings(TARGET my_app)
cmake_generic_build_infrastructure_set_pdb_output_directory(
	TARGET my_app
	OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/$<CONFIG>/bin"
)
```

このプロジェクトでは汎用compile設定にCPU・AVX2・計測設定を加える関数を使います。
PDBの出力先はプロジェクト側で指定します。
汎用モジュールは案件の変数を参照せず、他のリポジトリからも直接includeできます。
出力先と静的ランタイムの関数は後続targetの初期値を設定するため、target作成前に呼び出します。
CPU水準・出力レイアウト・静的ランタイムの採否は案件側で決めます。

```cmake
my_import_std_apply_compile_settings(TARGET my_import_std_app)
cmake_generic_build_infrastructure_set_pdb_output_directory(
	TARGET my_import_std_app
	OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/$<CONFIG>/bin"
)
```

PDB関数には絶対パスの`OUTPUT_DIRECTORY`を指定します。出力先は利用側で決めます。
WindowsのMSVC形式linker以外ではtargetを変更しません。プロジェクト関数は汎用のcompile設定に、
architecture・CPU基準・AVX2・instrumentationの設定を加えます。
キーワード引数にはCMake 4.4の`PARSE_ARGN`を使っています。固定引数の内部関数は4.5の
`ARGNC`で余分な引数を拒否します。未知引数や欠落値の検証は別途行います。
余分な引数の検証まで含めてこのヘルパーの契約どおり使うには、CMake 4.5以降が必要です。
関数内の作業変数はローカルです。出力先とランタイムの初期値は呼び出し元へ返します。
配布設定の一時変数と診断設定は
`block(SCOPE_FOR VARIABLES DIAGNOSTICS)`で隔離し、CPack設定ファイルはそのblock内で
生成します。SDKのinclude処理では変数スコープを作りません。

### オプション

| 設定 | 既定値 | 動作 |
|---|---|---|
| `MY_IMPORT_STD_ENABLE_PCH` | ON | アプリのPCHを有効化 |
| `MY_IMPORT_STD_BUILD_EXAMPLES` | OFF | [module利用例](../examples/module_consumer.cpp)をビルド。テスト有効時は実行も確認 |
| `MY_IMPORT_STD_ENABLE_AVX2` | OFF | 各プロジェクトtargetにAVX2フラグを適用。x86以外ではエラー |
| `MY_IMPORT_STD_TARGET_ARCH` | 空 | `x86_64`または`aarch64`を要求し、compilerの実targetを検証 |
| `MY_IMPORT_STD_CPU_BASELINE` | 空 | `x86-64-v3`または`armv8.2-a`を指定。通常のnative presetはarchitecture別に設定 |
| `MY_IMPORT_STD_TARGET_ENVIRONMENT` | 空 | `gnu`を指定するとLinux/glibcを要求。Linux presetで設定 |
| `MY_IMPORT_STD_USE_STATIC_RUNTIME` | OFF | MSVC ABIの静的runtimeを使用 |
| `MY_IMPORT_STD_ENABLE_PACKAGING` | OFF | ZIP生成とチェックサム検証targetを用意 |
| `MY_IMPORT_STD_ENABLE_INSTRUMENTATION` | OFF | build・test・installの時間と出力をローカルに保存。Clangではcompiler time traceも取得 |

AVX2を有効にした生成物にはAVX2対応CPUが必要です。実行時のCPU判定やfallbackはありません。
通常のnative presetではx86_64にx86-64-v3、AArch64にArmv8.2-Aを最低水準として指定します。
CPU水準はarchitectureとは独立した軸です。v3はAVX2だけの指定ではなく、FMA・BMI等を含み、
AVX-512は要求しません。Clang/GCCには`-march=x86-64-v3`、clang-clには
`/clang:-march=x86-64-v3`を用います。MSVCにはv3名の指定がないため`/arch:AVX2`を用います。
MSVCの`/arch:AVX2`はx86-64-v3全体を検証するものではありません。対応CPUの条件は
x86-64-v3として別に定めます。
Clang/GCCではv3の各命令セットを示すmacroもconfigure時に確認します。
Armv8.2-AはClang/GCCの`-march=armv8.2-a`、clang-clの`/clang:-march=armv8.2-a`、
MSVCの`/arch:armv8.2`で指定します。compilerがフラグに対応しない場合はエラーになります。
`MY_IMPORT_STD_ENABLE_AVX2=OFF`はCPU水準を下げません。v3指定とAVX2 ONの併用では
追加のAVX2フラグを重ねません。AArch64とAVX2 ONの組み合わせは拒否します。
空の値はtoolchain/compilerの既定値を使うための設定であり、未知の値や`*`は受け入れません。
CMakeが生成する標準ライブラリのBMIにも、利用targetに合わせたcompile設定が引き継がれます。
examplesはビルド用の利用例であり、配布パッケージには含めません。

配布先の既定値は`${PROJECT_SOURCE_DIR}/dist`です。
`CPACK_PACKAGE_DIRECTORY`に絶対パスを指定すれば変更できます。
ZIPのファイル名encodingはUTF-8を既定にし、`CPACK_ARCHIVE_ENCODING`で変更できます。
圧縮レベルは通常構成ではCPackの既定値を使い、検証用presetでは
`CPACK_ARCHIVE_COMPRESSION_LEVEL=6`を指定しています。

packageのバージョン互換性は`SemanticVersion`です。`0.y.z`ではminor versionまでの一致を
要求し、`1.y.z`以降ではmajor versionの一致を要求します。要求バージョンより古いpackageは
互換扱いにしません。この判定だけでcompiler・ABI・runtimeの互換性を保証するものではありません。

### toolchainの利用

Windowsの既存Ninja presetは[Windows toolchain](../cmake/toolchains/Windows.cmake)を使います。
MSVCのdeveloper環境から実行してください。Windows/Linuxのnative toolchainは
同じarchitectureへのビルドでは`CMAKE_SYSTEM_NAME`を新しく設定しません。
Windowsでホストと異なるarchitectureを対象にする場合は、Windowsへのクロスビルドとして設定します。
Windows ARM64用presetはARM64用MSVCツール・STL・Windows SDKが必要です。
VSのARM64用developer環境（例：x64ホストでは`vcvarsall.bat x64_arm64`）から実行してください。
`architecture`の`strategy: external`は開発環境を選ぶための情報であり、CLIから
compiler・SDKを自動インストールするものではありません。WindowsのClang targetは
architectureの指定からtoolchainが明示します。MSVCは選択済みcompilerの実targetを検証します。
クロスビルドしたARM64の実行テストは、ARM64環境または別途設定したemulatorで行ってください。

Linuxでは`x86_64-*-linux-gnu-clang++-Ninja_Multi_Config-x86_64_v3`または`x86_64-*-linux-gnu-g++-Ninja_Multi_Config-x86_64_v3`を使います。
対応compiler・標準ライブラリと、module dependency scannerが必要です。
Linux向けクロスビルドは今回の対象外です。
Linux AArch64用には`aarch64-*-linux-gnu-clang++-Ninja_Multi_Config-Armv8.2_A`または
`aarch64-*-linux-gnu-g++-Ninja_Multi_Config-Armv8.2_A`を使います。
両architectureともGNU/glibcに限定し、実際のcompiler macro・pointer幅と
`<features.h>`の`__GLIBC__`をconfigure時に検証します。musl環境は対象外です。
Linux・Windows ARM64のアプリと`import std`の実ビルドは未検証です。

Emscriptenは`*-*-emscripten-*-Emscripten_sdk-Ninja-Debug`を使います。`EMSCRIPTEN_ROOT`にSDKの絶対パスを指定するか、
環境変数`EMSCRIPTEN`または`EMSDK`を設定してください。
`cmake/Modules/Platform/Emscripten.cmake`へ処理を委譲します。

WASIは`*-*-*-*-WASI_sdk-Ninja-Debug`を使います。`WASI_SDK_PATH`にSDKの絶対パスを指定します。
環境変数`WASI_SDK_PATH`でも指定できます。`share/cmake/wasi-sdk.cmake`へ処理を委譲します。
SDKの不足や無効なパスはエラーになり、別compilerへ切り替えません。

compilerが標準ライブラリmoduleのmetadataを発見できない場合に限り、SDKまたは利用者の
presetから`CMAKE_CXX_STDLIB_MODULES_JSON`へmetadataファイルのパスを指定できます。
通常は自動検出を使います。この設定でSDKにないmodule対応を追加することはできません。

### 将来の配置処理

現在は配置するassets等がないため、配置ヘルパーは新設していません。
導入する場合は次の条件を満たします。

- 配置先を`$<TARGET_FILE_DIR:...>`など、targetの実際の出力先に接続する。
- single/multi-configに対応し、配置する入力と上書き範囲を明示する。
- link/copyなどの許容値を検証し、fallbackする時は理由を通知する。
- 削除はヘルパーが管理する確認済みの出力に限定し、任意の既存ディレクトリを削除しない。

パスの範囲判定には正規化後の`PATH_IS_PREFIX`を使えます。ただし字句上の比較であり、
symlinkを解決した配置先・削除先の確認にはなりません。

### 検証

CTestでmodule・アプリ・有効にしたexampleの実行、共通関数の入力検証、
チェックサムの正常系・異常系、SDK委譲の変数スコープと不足時の診断を確認します。
SDK委譲のテストにはfixtureを使い、実SDKでのビルド成功を示すものではありません。
共通関数のテストはnested configureを行うため、WindowsではCTestもdeveloper環境から
実行してください。

実施記録とinstall後の利用側検証は[作業計画](../work/cmake-refactoring/PLAN.md)にあります。

### presetの継承軸

[通常のpreset](../CMakePresets.json)はプロジェクト共通設定と公開する構成を定義し、
[汎用ビルド基盤の軸](../cmake/presets/CMakeGenericBuildInfrastructurePresets.json)と
[プロジェクト軸](../cmake/presets/CMakeProjectPresets.json)をincludeしています。
汎用ビルド基盤の軸にはプロジェクト変数やプロジェクト内のパスを含めず、別リポジトリからも直接includeできます。
プロジェクト軸に置くのはtoolchainの場所、CPU要件、機能選択、短い出力先です。
ホスト・target/toolchain・generator・compiler・linker・機能・診断・操作をhidden presetに分け、
公開presetの`inherits`で組み合わせます。preset名は以下の命名規約へ変更しています。

| 軸 | preset名の例 | 設定する内容 |
|---|---|---|
| プロジェクト共通 | `base:project` | 言語規格、機能の既定値、出力先 |
| ホスト | `host:Windows`、`host:Linux` | `${hostSystemName}`による利用条件 |
| target/toolchain | `system:Windows(host:Windows)`、`system:WASI` | 対象環境のtoolchainファイル |
| generator | `generator:Ninja_Multi_Config`、`generator:Ninja` | 生成器だけの選択 |
| ビルド構成 | `build_types:Debug_Release_RelWithDebInfo`、`build_type:Debug(generator:single_config)` | 構成一覧とsingle-configの構成指定 |
| architecture/toolset | `architecture:x64(strategy:external)`、`toolset:version(strategy:external)` | 外部環境によるarchitecture・toolsetの選択 |
| compiler | `compiler:clang_cl`、`compiler:clang++(system:Linux)` | compilerの実行ファイル |
| linker | `linker:LLD` | 明示的なlinker選択 |
| 機能 | `feature:Packaging`、`feature:Instrumentation` | 既定値からの機能切り替え |
| 診断 | `diagnostics:Developer`、`diagnostics:Strict_warnings` | 警告とエラーの方針 |
| debug/trace | `debug:Quiet`、`trace:Expanded` | configureの出力とtrace設定 |
| build操作 | `install-operation:Default`、`verify-checksum-operation:Default` | 実行するtarget |
| test出力 | `test-output:On_failure` | 失敗したテストの出力表示 |
| 配布形式 | `package-format:ZIP` | CPackの出力形式 |
| 出力先 | `layout:Windows_clang_cl` | preset名から独立したbuild・install先 |

`bundle:development`は`base:project`と共有の警告・エラー方針を組み合わせる便宜presetです。
色付き診断、configureのdebug/trace、インストール時の表示量、テスト失敗時の出力表示は
共有構成では選択せず、利用者の設定に分けています。汎用軸にあるdebug/traceやtest出力の
部品は、利用者が必要に応じて継承できます。`CMAKE_EXPORT_COMPILE_COMMANDS`は
開発ツール連携のため共有側に残しています。
`bundle:development-Ninja_Multi_Config`は共通設定・Ninja Multi-Config・構成一覧・既定のDebug構成を
組み合わせます。generator軸そのものは構成一覧を変更しません。
`CMAKE_DEFAULT_BUILD_TYPE`はNinja Multi-Config向けの既定構成指定です。
single-configにはDebug/Release/RelWithDebInfoの`build_type:*(generator:single_config)`を用意しています。
build/test/packageの構成選択も、それぞれ`build-build_type:*`・`test-build_type:*`・
`package-build_type:*`から継承します。
異なる種類のpreset同士では継承できないため、構成名は種類ごとに定義しています。
`CMAKE_CONFIGURATION_TYPES`は構成一覧の軸で指定し、single-configのSDK向けには
指定しません。native toolchainは`CMAKE_SYSTEM_NAME`を強制せず、SDKのcompiler選択は
SDK付属toolchainへ委譲します。frontend別のcompile設定は引き続きtarget側で適用します。
MSVCのlinkerは従来どおり既定の選択を使い、空のfrontend・linker用presetは作っていません。

複数の親が同じ設定を持つ場合は、`inherits`の先の親が優先されます。
そのため、機能を有効・無効にするpresetは、既定値を持つ共通設定より先に継承してください。
複数の親の`condition`は自動的にANDされません。利用条件はホスト軸だけに持たせ、
複数の条件が必要になった場合は組み合わせるpresetで明示してください。
Visual Studioの無効化は公開presetの`condition: false`に残しています。
軸を分けても任意の組み合わせを保証するものではありません。ASanの設定はclang-clの
Debug構成向けで、AVX2・静的runtime・SDKにはそれぞれtargetやtoolchain側の制約があります。
`feature:ASan(compiler:clang_cl,build_type:Debug)`はDebug用のcompiler/linkerフラグだけを設定します。
Debugだけを生成する方針は`build_types:Debug`へ分け、
`bundle:ASan-clang_cl-Debug`をルートの組み合わせ済みpresetとして用意しています。
toolsetの`version=`と空コメントは準備用の値を維持しており、実際のversion指定は別途必要です。

### 利用者のプリセット

個人の表示設定はルートの`CMakeUserPresets.json`に置きます。このファイルはGitの追跡対象から
除外してあり、共有presetからはincludeしません。CMakeは同じディレクトリの
`CMakePresets.json`を暗黙に読み込むため、個人側から共有presetを継承できます。
共有側から個人側を継承することはできません。

現在のローカルファイルには、Windows clang-cl用の`user-windows-clang_cl`と
Debug/Releaseのbuild・test、Debugのworkflowを用意しています。
共有構成とキャッシュが混ざらないよう、build・install先は個人用に分けています。

```powershell
cmake --workflow --preset validation-user-windows-clang_cl-Debug
```

個人用ファイルがない環境では共有presetをそのまま利用できます。
別環境で個人設定を作る場合は、例えば次の内容を`CMakeUserPresets.json`に保存します。
build・test・workflowも個人用configureを参照するpresetとして別途定義します。

```json
{
  "version": 13,
  "configurePresets": [
    {
      "name": "user-windows-clang_cl",
      "inherits": [
        "debug:Output",
        "trace:Expanded",
        "x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3"
      ],
      "binaryDir": "${sourceDir}/build/user-windows-clangcl",
      "installDir": "${sourceDir}/install/user-windows-clangcl",
      "cacheVariables": {
        "CMAKE_COLOR_DIAGNOSTICS": true,
        "CMAKE_INSTALL_MESSAGE": "ALWAYS"
      }
    }
  ]
}
```

既存のbuildディレクトリに残るキャッシュ値は、共有presetから設定を取り除いても消えません。
共有側の既定動作を確認する場合は、新しいbuildディレクトリを使います。
traceの相対パスはCMakeの起動ディレクトリが基準です。現在の設定ではそのディレクトリの
`trace_log.jsonl`へ保存し、ルートにできるファイルはGitの追跡対象から除外しています。
`trace.redirect`はマクロ展開されません。保存先を変える場合は、既存のディレクトリを
指すパスを個人用presetで指定します。

buildの`targets`やpackageの`generators`・`configurations`は、継承でリストを結合しません。
そのため、テストとinstallの両方を準備する操作には、両targetを明示した
`build-prepare-operation:Test_and_install`を使います。これは操作の組み合わせであり、
compilerやDebug/Releaseの選択は含みません。workflowは組み合わせたpresetを順に実行します。

[presetのテスト](../tests/cmake/RunPresetChecks.cmake)ではgeneratorへの構成設定の混入、
ASanへの構成一覧の混入、操作へのcompiler接続などを検出します。
ルートのconfigure presetは軸の組み合わせとプロジェクト共通設定に限定しています。

### presetの命名規約

単独の軸は`軸名:選択値`、他の設定への依存は半角丸括弧で示します。
`-`は異なる部品の区切り、`_`は部品名内の半角スペースの代用です。
ツール名の`clang-cl`等はpreset名では`clang_cl`とし、実際のcompiler指定は変更しません。
`base:`は基本設定、`bundle:`は複数設定の組み合わせを表し、直交軸とは区別します。
括弧内は依存関係の説明であり、CMakeが名前から条件を解釈するものではありません。

組み合わせ済みpresetはLLVMの
[Triple](https://llvm.org/doxygen/classllvm_1_1Triple.html)の
`architecture-vendor-operating_system[-environment]`を先頭にし、
[Clang設定ファイル](https://clang.llvm.org/docs/UsersManual.html#configuration-files)の
`<triple>-<driver>`に倣ってcompiler driverを続けます。
その後のlinker・generator・CPU水準・ビルド構成・機能の順は、このプロジェクトの規約です。
triple内部の`x86_64`等は正式な表記を保持し、スペース置換の規則は適用しません。
`msvc`は対象環境を表し、compilerがcl.exeであることを意味しません。

Windowsの既定のx64 developer環境では、Clangのtargetが
`x86_64-pc-windows-msvc`であることを確認しています。
native presetはx86_64/AArch64を分け、Linuxのenvironmentは`gnu`に固定しています。
未指定のtriple要素は`*`とし、Linuxのvendorは未指定のままです。
Emscriptenは`*-*-emscripten-*`、WASIは`*-*-*-*`にSDK名を続けます。
WASIはSDKにより`wasi`・`wasip1`・`wasip2`等のOS表記が異なるため、この要素も未指定です。
SDKには引き続きtargetを委譲し、architecture・vendor・environment・WASIの世代を推測しません。
`*`はこのプロジェクトのpreset名だけの記法であり、compilerの`--target`に渡す値でも
LLVMの`unknown` vendorと同じ値でもありません。CLIでは`*`を含むpreset名を引用してください。

configure/workflow以外のpresetは、`build-`・`build-prepare-`・`install-`・`test-`・
`package-ZIP-`・`verify-checksum-`等の操作接頭辞を付けます。
workflowには`validation`や`distribution`という流れの目的を付けています。
命名順と`inherits`の優先順は別です。

| 旧configure preset名 | 新configure preset名 |
|---|---|
| `ninja-multi-clangcl` | `x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3` |
| `ninja-multi-clang` | `x86_64-pc-windows-msvc-clang++-lld_link-Ninja_Multi_Config-x86_64_v3` |
| `ninja-multi-cl` | `x86_64-pc-windows-msvc-cl-Ninja_Multi_Config-x86_64_v3` |
| `ninja-multi-linux-clang` | `x86_64-*-linux-gnu-clang++-Ninja_Multi_Config-x86_64_v3` |
| `ninja-multi-linux-gcc` | `x86_64-*-linux-gnu-g++-Ninja_Multi_Config-x86_64_v3` |
| `ninja-emscripten` | `*-*-emscripten-*-Emscripten_sdk-Ninja-Debug` |
| `ninja-wasi` | `*-*-*-*-WASI_sdk-Ninja-Debug` |

旧名のaliasは残していません。長いpreset名をディレクトリ名に使うとWindowsのnested testで
パス長問題が起きるため、既存の構成には`layout:*`を先に継承させ、従来の短いbuild・install・
ZIP出力先を維持しています。ディレクトリ名に残る旧名は保存先の識別子です。
layoutを指定しない新規構成では、baseの`${presetName}`等による出力先が使われます。
ただし`*`を含む名前はWindowsのパスに使えないため、必ず明示的なlayoutを継承してください。

### 独立した検証用preset

[作業用preset](../work/cmake-refactoring/CMakePresets.json)は通常のpresetをincludeし、
`--presets-file`で明示的に読み込みます。`${fileDir}`はinclude元の場所を、
`${configurePresetName}`は対応するconfigure preset名を表します。
build・install・ZIPはpresetごとの専用ディレクトリに分けています。
Windowsではdeveloper環境から、プロジェクトルートで実行してください。

```powershell
$presets = "work\cmake-refactoring\CMakePresets.json"
cmake --workflow --presets-file $presets --preset validation-x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-Debug-examples
cmake --workflow --presets-file $presets --preset distribution-x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-Release-validation
```

検証用configure presetは通常の構成名に`-validation`を付けています。
clang++版はPCH OFF、cl版はPCH OFF・静的runtime ONです。
対応するDebug/Releaseのbuild/test presetもあります。
build presetは`test_prep/all`、Releaseでは追加で`install_prep/all`を使います。
これらは依存する生成物を準備するtargetであり、CTestやinstall自体は実行しません。
任意のビルド先に同じbuild設定を適用する場合は、`cmake --build <dir> --preset <name>`
と`--presets-file`を併用できます。

通常のpresetと検証用presetではstrict診断をエラーにし、target単位の代替がある
directory設定や、installの絶対`DESTINATION`を検出します。配布設定はpresetを使わない
場合にも絶対`DESTINATION`をエラーにします。絶対install prefixやZIP出力先は許可します。
従来の`CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION`のpreset指定は取り除きました。

### 差分テストと環境変更

`ctest --out-of-date`で、最後の実行以降に依存ファイルが更新されたテストだけを選べます。
スクリプトテストには`BUILD_DEPENDS`で入力スクリプト等を登録しています。
この選択はcompilerやSDKの外部変更をすべて検知するものではありません。
環境変更後と最終検証では通常の全件実行を使います。

```powershell
ctest --presets-file $presets --preset test-x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-Debug-validation --out-of-date
```

環境を管理する呼び出し側は、`CMAKE_SYSTEM_ENVIRONMENT_ID`にcompiler・SDK等の構成を
識別できる値を設定できます。値が変わるとCMakeがcache再利用に警告を出します。
IDはCMakeが自動計算するものではありません。ツール更新時に呼び出し側で更新し、
必要に応じて`--fresh`を使ってください。固定のIDをテンプレートには埋め込みません。
SDKのfixtureテストでは`execute_process()`の`ENVIRONMENT`と
`ENVIRONMENT_MODIFICATION`で子プロセスの環境だけを制御します。

### ローカル計測

```powershell
cmake --presets-file $presets --preset x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-validation-instrumentation
cmake --build --presets-file $presets --preset build-prepare-x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-Debug-validation-instrumentation
ctest --presets-file $presets --preset test-x86_64-pc-windows-msvc-clang_cl-lld_link-Ninja_Multi_Config-x86_64_v3-Debug-validation-instrumentation
```

clang++には上記の名前の`clang_cl`を`clang++`に置き換えたconfigure/build/test presetを使います。計測時は
`captureOutput`・`compileTrace`・Google Traceを有効にし、Clangの通常targetに
`-ftime-trace`を適用します。通常構成のフラグには追加しません。

CMakeはindex処理後に元のsnippetを削除するため、
[保存用callback](../cmake/generic-build-infrastructure/SaveInstrumentation.cmake)が参照先を
`<build>/instrumentation`へコピーします。indexの`dataDir`も保存先へ更新します。
計測indexは`index/`、Google Traceは`trace/`、取得できたcompiler traceは`compile-trace/`に残ります。
callbackは元のデータを移動・削除せず、CMakeが示したデータディレクトリ内の相対パスだけを扱います。
範囲の検証は正規化後の字句比較であり、信頼できない外部indexを処理する用途ではありません。
記録は蓄積するため、不要になった時は当該buildの`instrumentation`だけを整理してください。
出力にはコマンド・ローカルパス・診断等が含まれます。外部送信は行いません。

targetや設定の調査には、CMake 4.5の`cmake_language(PRINT_TARGETS)`・
`PRINT_PROPERTIES`・`PRINT_VARIABLES`も利用できます。通常configureには常設しません。
