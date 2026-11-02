# CMake構成改善の作業計画

## 目的と現在の状態

`my_cxx_generic_build_infrastructure`を汎用C++開発基盤として再利用できる構成に近づけるため、
選択済みの改善を段階的に実施する。構造の整理と動作の変更を区別し、各段階で検証する。

- 選択済みの変更を実装し、Windowsでビルド・テスト・配布を検証済み。
- Linux・Emscripten・WASIの実ビルドは未検証。SDK委譲のfixture検証と不足時の診断は確認済み。
- 計画と検証用ファイルは、この作業ディレクトリに置く。
- 既存のbuildディレクトリを削除・上書きせず、検証には区別できるビルド先を使う。
- TechDemoGameのstashは参考資料として読み取り、適用・変更しない。
- 本計画に記載した構成はビルド成功を確認済みという意味ではない。

## 対象ファイル

- [ルートCMakeLists.txt](../../CMakeLists.txt)
- [CMakePresets.json](../../CMakePresets.json)
- [cmakeディレクトリ](../../cmake)
- [tests/CMakeLists.txt](../../tests/CMakeLists.txt)
- [アプリのソース](../../src/app/main.cpp)
- [ソース構成の説明](../../src/README.md)

## target・CPU水準の明示

利用者の選択に従い、Windows/Linuxともx86_64とAArch64を別の構成として扱う。
x86_64はx86-64-v3、AArch64はArmv8.2-A、Linuxの実行環境はGNU/glibcに限定する。
未指定のtriple要素は`@`にする。CPU水準はtripleに含めず、独立した軸で指定する。

- [x] architecture・CPU水準・実行環境の軸を用意し、native presetへ接続する。
- [x] compilerの実target・pointer幅・glibcと、CPUフラグの対応をconfigure時に検証する。
- [x] 各targetにCPU設定を適用し、既存AVX2設定との重複・衝突を処理する。
- [x] 未指定のSDK targetを推測せず、wildcard名と短いlayoutを使う。
- [x] AArch64とLinuxのDebug/Release build/test presetを接続する。
- [x] Windows x64の3 compilerでビルド・テスト・配布を再検証する。
- [x] schemaのフィールド順、preset参照、CPU設定と名前の対応を検証する。

ClangでARM64のcompile設定とCOFF-ARM64のobject生成を確認した。
現在のVSにはARM64用compiler/SDKライブラリの開発環境が揃っていないため、
Windows ARM64の`import std`・リンク・実行は未検証。Linuxの実ビルドも未検証。
MSVCの`/arch:AVX2`はv3名の指定ではないため、Clang/GCCのv3 feature macro検証と
同等の確認とは扱わない。MSVC生成物の対応CPU条件はv3として文書化する。

検証結果

- Windows x64のclang-cl・clang++・MSVC：Debug/Releaseとも各8テスト成功。
- Clangの2計測構成：Debugの構築と各8テスト成功。
- clang-clのRelease配布workflow：5段階成功。ZIP・SHA-256検証・installを確認。
- helper検証は37ケース。CPUフラグのcompiler別対応、architecture/CPUの衝突、
  未知の値、非glibc環境の拒否を追加。
- Windows toolchainのfixtureでnative/crossの両architecture、target衝突、
  不正値、ホスト条件、一時変数の隔離を確認。
- 3 JSONファイルの公式schema検証と、`$comment`を除くフィールド順の照合に成功。
- preset参照、4要素のtriple記法、CPU軸と名前、wildcardが出力パスに入らないことを確認。
- compile databaseのclang-cl 27件・clang++ 24件・MSVC 24件すべてでCPUフラグを確認。
- 日本語は目視で確認。`yomiyasu-check: not_run reason=no_python`。

## 採用する改善

以下のチェックは採用決定を表す。作業の完了状態は後述の実施チェックリストで管理する。

### 分割

- [x] 共通target設定を専用モジュールへ切り出す。
- [x] install/export設定をプロジェクト固有の別ファイルへ切り出す。
- [x] OS・SDK別toolchainを現行へ導入し、presetへ接続する。

### 関数・設定の様式

- [x] 共通設定関数の名前を実際の責務に合わせる。
- [x] 現在の関数にもキーワード引数を導入する。
- [x] 引数を保持できる解析形式を使う。当初の`PARSE_ARGV`から、追加改善で`PARSE_ARGN`へ移行する。
- [x] 必須引数・未知の引数・値の欠落・許容値・targetの存在を検証する。
- [x] 関数定義モジュールに`include_guard`を付ける。
- [x] `block(SCOPE_FOR VARIABLES)`による積極的な隔離を検討する。
- [x] target中心の設定とfrontend別generator expressionを維持する。
- [x] キャッシュの`FORCE`は必要性を説明できる場合に限定する。

### パス・動作・保守性

- [x] パスの基準をプロジェクト入力・同梱ファイル・指定出力先で区別する。
- [x] 単一パス・単一コマンド引数の引用を統一する。
- [x] 配置処理はtargetの実際の出力先へ接続する。
- [x] fallback・上書き・削除の契約を明示する。
- [x] オプション宣言と実際の動作を対応させる。
- [x] インデント・改行の様式を統一する。
- [x] 公開ヘルパーの入力・副作用・制約を説明する。
- [x] 未使用ヘルパー・古いコメントアウトコードを整理する。

## 今回行わない変更

- CPack専用ファイルへの分割。
  install/exportと同じプロジェクト固有ファイル内でセクションを分ける。
- app・moduleのtarget定義の子ディレクトリへの移動。
- 警告・文字コード・例外処理の個別関数への細分化。
- 削除済みのclangd向けcompiler rule回避策の復活。
- チャットで比較するための一時的なworkspace参照の整理。
- 空のtoolchainや、用途のない配置処理を作るだけの変更。

## 確定した実装方針

| 事項 | 現在の状態 | 決める内容 |
|---|---|---|
| toolchainの範囲 | 利用者が選択済み | Windows native、Linux native、Emscripten、WASI。Linux向けクロスビルドは対象外 |
| 検証環境 | Windowsで検証可能 | VSのMSVC、LLVMのclang-cl/clang++、Ninja、CMake。Linux実機・有効なEmscripten/WASI SDKは未確認 |
| modules OFF | 廃止する方針に確定 | module必須。旧オプションのOFFを明示的に拒否 |
| examples | 実装する方針に確定 | module利用例のtargetと、有効時の実行テストを追加 |
| AVX2 | 実装する方針に確定 | x86用のopt-inフラグ。非x86では拒否し、実行時fallbackは設けない |
| 配置処理 | 新設しない方針に確定 | 将来の入力・配置先・fallback・削除範囲の条件を文書化 |

挙動や対応範囲が変わる判断は、実装前に利用者へ確認する。
toolchain導入自体は見送らず、対象を決めて実際の設定を用意する。

## 実施チェックリスト

### 1. 対応範囲と基準動作の確定

- [x] 上記の未確定事項を決める。
- [x] presetと実際のconfigure・build・testの対応を確認する。
- [x] 現状で成立する構成と、既存の失敗を記録する。
- [x] 検証用のビルド先と、変更後の検証対象を確定する。

完了条件：対象構成、意図的な動作変更、検証可能な範囲が明確であること。

### 2. オプションと動作の整合

前提：段階1。

- [x] modules OFF・examples・AVX2を決定内容に合わせて整理する。
- [x] 現行CMakeのmodule関連設定とgeneratorの対応を確認する。
- [x] 必要なPDB設定を対象targetへ接続し、不要なコードを整理する。
- [x] Windowsの対応構成でbuild・testし、変更したオプションの挙動を確認する。

完了条件：公開する選択肢が実装に対応し、対象構成が成立すること。

### 3. 共通target設定の切り出し

前提：段階2。

- [x] 共通関数を専用の関数定義モジュールへ移す。
- [x] 責務に合わせて関数名を変更する。
- [x] 既存関数を`TARGET ...`形式へ変更し、引数解析と検証を導入する。
- [x] root・testsを含め、全呼び出し元を更新する。
- [x] `include_guard`を付け、契約を説明する。
- [x] 関数外の一時変数を隔離できるか確認する。
- [x] 正常な呼び出しと、不正な呼び出しの診断を検証する。
- [x] ビルド時の適用フラグが意図せず変わっていないことを確認する。

完了条件：全targetへの適用が維持され、不正入力が明確に失敗すること。

### 4. install/export・packagingの整理

前提：段階3。

- [x] install/exportとCPackを、プロジェクト固有の設定ファイル1つへ移す。
- [x] 公開namespace・インストール先・パッケージ名の既存仕様を保つ。
- [x] パスの基準と引用を整理する。
- [x] 一時変数を隔離しつつ、CPackに必要な変数の伝播を維持する。
- [x] install・利用側からの読み込みとbuild・ZIP生成・検査合計を検証する。

完了条件：分割前の配布仕様が保たれ、生成物を利用側から使えること。

### 5. OS・SDK別toolchainの導入

前提：段階1で対象を確定、段階2でソースの対応方針を確定。
変更後の統合検証は段階4までの変更と合わせて行う。

- [x] 対象ごとにcompiler・ターゲット・SDK・sysroot等の必要設定を用意する。
- [x] toolchainとpresetを接続する。
- [x] ホストのツール配置と生成物の対象環境を区別する。
- [x] ネイティブ構成を不必要にクロスコンパイル扱いにしない。
- [x] SDK付属toolchainの設定をスコープ隔離で失わないことをfixtureで確認する。
- [x] SDK不足・無効なパスなどを明示的に診断する。
- [x] Windowsでconfigure・buildし、未検証の範囲を記録する。
- [ ] Linux実機・実SDKでconfigure・build・実行を検証する。

完了条件：空の骨組みではなく、接続された設定と検証範囲の説明があること。
未検証の構成は対応確認済みとして扱わない。

### 6. 配置処理の契約

前提：段階1で新設の要否を確定。

- [x] 今回は配置処理を新設しない方針を確定する。
- [x] target出力先・single/multi-config・入力・fallback・削除範囲の条件を関連文書に記載する。

完了条件：必要な機能の安全な実装、または新設しない判断と契約の記録があること。

### 7. 書式・説明と最終検証

前提：段階2〜6。

- [x] CMakeコードのインデント・改行を現在の主流の様式に統一する。
- [x] 不要なコメントアウトと、説明の不一致を整理する。
- [x] ヘルパー・toolchain・オプションの使い方を更新する。
- [x] Windowsで実施可能な検証を実行し、結果と未検証事項を記録する。

## 最終検証の条件

| 検証 | 確認する内容 |
|---|---|
| 対応構成 | Debug/Releaseのconfigure・build・test |
| オプション | 対応すると決めたON/OFFの挙動 |
| ヘルパー | 正常入力、未知引数、欠落値、存在しないtarget、許容値違反 |
| パス | 空白を含むパス、適切なsource/binary/定義側directoryの使用 |
| install/export | 利用側プロジェクトでの読み込み・build・必要に応じた実行 |
| packaging | ZIP内容、検査合計成功、不正データの失敗 |
| toolchain | SDK不足の診断、対象環境の生成物、実行または実行不能の理由 |
| 配置処理 | 新設した場合の出力先変更、構成別配置、fallback通知、削除範囲 |

検証結果は実行後に追記する。未実行の項目を成功として扱わない。

## 作業記録

- 利用者の指定に従い、module必須、examples/AVX2実装、4種類のtoolchain（Windows・Linux・Emscripten・WASI向け）の導入、
  配置処理の文書化を確定した。
- 変更前にWindowsのclang-cl・clang++・MSVCでDebug/Releaseのbuildとmoduleテストが成功。
  初回clang-cl DebugではIPOをOFFにしたが、Release確認前にpreset既定のONへ戻した。
- 共通関数とinstall/export・CPackを切り出し、既存関数をキーワード引数へ変更した。
- install側にmodule export情報のディレクトリ指定を追加し、利用側でmoduleを使えることを確認した。
- CPackの変数をverbatimで保存し、バックスラッシュと空白を含む出力先に対応した。
- examplesはmodule利用例として実装した。AVX2は既定OFFとし、x86 targetにのみ適用する。
- module必須とimport stdの制約に合わせ、Visual Studio presetを無効にした。
- SDKはインストールしていない。Emscripten/WASIは実験的presetとし、対応確認済みとは扱わない。

### 検証結果

| 構成・検証 | 結果 |
|---|---|
| clang-cl、Ninja Multi-Config、Debug/Release、examples/AVX2/PCH ON | build成功、CTest各6件成功 |
| clang++、Ninja Multi-Config、Debug/Release、examples/AVX2/PCH ON | build成功、CTest各6件成功 |
| MSVC、Ninja Multi-Config、Debug/Release、examples/AVX2/PCH OFF | build成功、CTest各5件成功 |
| clang-cl、Ninja single-config、Debug、静的runtime ON・PCH OFF | build・CTest成功 |
| modules OFF | 意図したconfigureエラーを確認 |
| 共通関数 | 正常系、AVX2設定、非x86、未知引数、欠落値、無効target、PDB引数、OFFという名前や引数等の19ケース成功 |
| 検査合計 | 正常・大文字hash・空白入りファイル名、形式不正・長さ不正・欠落・不一致の診断を確認 |
| Windows toolchain | 実buildと接続を確認 |
| Linux toolchain | Windowsホストを明示的に拒否。Linux実機では未検証 |
| Emscripten/WASI | SDK不足時のエラー、fixtureによる委譲と通常変数の伝播を確認。実SDKでは未検証 |
| install/export | clang-cl Releaseをinstallし、利用側のconfigure/build/CTestが成功 |
| ZIP生成 | アプリ・ライブラリ・moduleソース/BMI・package設定を確認。examples/testsは含まれない |
| 配布先 | 空白・バックスラッシュを含むパスでZIP生成と検証targetが成功 |
| PDB | Debugのアプリ・example・testのPDBが指定binに生成されることを確認 |
| preset | `cmake --list-presets=all`が成功 |
| compile flags | clang-clの既存警告・文字コード・言語準拠・例外設定の出現数を維持。MSVC/GNU frontendのAVX2 ONとOFFを生成コマンドで確認 |
| native判定 | Windows toolchain使用時の`CMAKE_CROSSCOMPILING`がFALSEであることを確認 |

CMakeが生成する標準ライブラリのsynthetic BMIにも、利用targetに合わせたAVX2設定が
引き継がれることを確認した。これを避けるcompiler ruleの書き換えは行っていない。

### 再検証用の場所

- clang-cl：`build\cmake refactoring clangcl`
- clang++：`build\cmake-refactoring-clang`
- MSVC：`build\cmake-refactoring-cl`
- single-config静的runtime：`build\cmake-refactoring-static`
- install先：`install\cmake refactoring clangcl`
- 利用側ソース：[consumer/CMakeLists.txt](consumer/CMakeLists.txt)
- 利用側build：`build\cmake refactoring consumer`
- ZIP出力先：`build\cmake refactoring clangcl\packages`

WindowsではMSVCのdeveloper環境で実行する。

```powershell
cmake --build "build\cmake refactoring clangcl" --config Debug
ctest --test-dir "build\cmake refactoring clangcl" -C Debug --output-on-failure
cmake --build "build\cmake refactoring clangcl" --config Release
ctest --test-dir "build\cmake refactoring clangcl" -C Release --output-on-failure
cpack --config "build\cmake refactoring clangcl\CPackConfig.cmake" -C Release
cmake --build "build\cmake refactoring clangcl" --config Release --target verify-package-checksum
```

### 残る検証

- Linuxのcompiler・標準ライブラリ・scannerの組み合わせで実buildする。
- Emscripten/WASIの実SDKでmodule/import stdの対応を確認する。
- 構成を増やす場合は、利用側とのcompiler・ABI・runtimeの互換性を検証する。
- 日本語説明は目視で確認した。既存Python launcherが起動に失敗したため、
  yomiyasuの自動検査は未実行。

## CMake 4.3-4.5の追加採用

利用者の指定に従い、現在に適用できる機能から順に採用する。用途がまだない機能のためだけに
新しい処理は作らず、必要となる条件を残す。

### 実施順と完了条件

1. 引数解析とtarget検証を更新する。
   - [x] 公開関数を`PARSE_ARGN`へ変更し、固定引数関数に`ARGNC`検証を追加。
   - [x] ローカルcompiled targetへのaliasを許可し、imported/interfaceへのaliasは拒否。
   - [x] false-like値、空の追加引数、欠落値、参照先への設定を検証。
2. 診断と独立した検証用presetを用意する。
   - [x] strict・non-target directive・絶対install destinationの診断を接続。
   - [x] 配布設定で変数と診断のスコープを隔離。
   - [x] `--presets-file`、`${fileDir}`、`${configurePresetName}`を作業用presetで使用。
   - [x] `test_prep/all`と`install_prep/all`をbuild presetへ接続。
3. 配布とテストのmetadataを更新する。
   - [x] `SemanticVersion`へ変更し、0.xと1.xの互換判定を検証。
   - [x] スクリプトテストに`BUILD_DEPENDS`を登録。
   - [x] SDK fixtureの子プロセス環境を明示的に制御。
   - [x] UTF-8 ZIP encodingを既定にし、作業用presetで圧縮レベル6を指定。
4. 条件付き機能を通常構成から分ける。
   - [x] 既定OFFのinstrumentationと両Clang frontendの計測presetを導入。
   - [x] index・snippet・compiler traceをローカルへコピーし、CMakeによるcleanup後も保持。
   - [x] 保存処理で`ARRAY_SPLIT`・`STRING_ENCODE`・`math(DECREMENT)`・正規化後の`PATH_IS_PREFIX`を使用。
   - [x] 環境ID変更の警告、差分テスト選択、UTF-8 ZIPの日本語ファイル名をfixtureで検証。
   - [x] SDK metadata明示、環境ID運用、診断用PRINTコマンドの利用条件を説明。
5. Windows統合検証と記録を更新する。
   - [x] 最終状態のDebug/Release・計測構成・配布・install consumerを確認し、結果を記録。

### 今回は実処理へ導入しない機能

| 機能 | 導入する条件 |
|---|---|
| `SOURCES` file setとfile set属性 | ソース群ごとにPCH・lint・job pool等を変える必要が生じた時 |
| `add_custom_rule()` | 繰り返しのコード生成処理が必要になった時 |
| CPS・SBOM | 配布metadataと対象利用者が決まり、C++ moduleの配布要件を満たせる時 |
| `RUNTIME_DEPENDENCY_TARGETS` | 配布するshared library依存ができ、exportとは別のruntime installを設計する時 |
| `discover_tests()` | 実行時のテスト列挙を提供するframework等を使う時 |
| list predicate・compile/link wrapper | 現行の簡単な設定で表せない具体的な処理ができた時 |

`CMAKE_CXX_STDLIB_MODULES_JSON`と`CMAKE_SYSTEM_ENVIRONMENT_ID`は呼び出し側で必要な時だけ
指定する。用途のない固定パス・固定IDは追加しない。Linux・実SDKの未検証状態は引き続き残る。

### 追加採用の検証結果

CMake 4.5.0-rc1、Windows、Ninja Multi-Configで実行した。

| 検証 | 結果 |
|---|---|
| clang-cl、PCH ON、Debug/Release | 作業用workflowが成功。CTest各7件成功 |
| clang++、PCH OFF、Debug/Release | buildとCTest各7件成功 |
| MSVC、PCH OFF・静的runtime ON、Debug/Release | buildとCTest各7件成功 |
| 共通関数と診断 | 26ケース成功。alias設定、空の追加引数、instrumentationとAVX2の独立性、診断スコープを確認 |
| clang-cl計測 | buildとCTest7件成功。保存したcompile snippet14件の出力フィールド、非nullのcompiler trace参照6件とコピー先を確認 |
| clang++計測 | buildとCTest7件成功。保存したcompile snippet13件の出力フィールド、非nullのcompiler trace参照5件とコピー先を確認 |
| 通常構成 | compile databaseに`-ftime-trace`がないことを確認 |
| preparation target | 生成済みの`test_prep/all`・`install_prep/all`をbuild presetとfixtureで実行 |
| 差分テスト | fixtureで未更新の依存をskipし、入力更新後に該当テスト1件だけを実行 |
| 環境ID | 子プロセスのID変更でcache再利用への警告を確認 |
| SDK環境 | 明示したSDKパス・環境変数経由のfixture委譲・不足診断を、親環境を変更せず確認 |
| ZIP | UTF-8の日本語・空白入りファイル名を圧縮レベル6で作成し、展開後の名前と内容を確認 |
| 配布とconsumer | Release ZIPとSHA-256検証成功。install後のfind_package・module利用側build・CTest成功 |
| presetと作業場所 | ルートpresetと作業用presetの一覧表示が成功。ソース外の作業ディレクトリから、明示したbuild先とbuild presetの併用も成功 |
| 保存callback | indexの`dataDir`更新とsnippetコピーをfixtureで確認。Windowsのバックスラッシュを含む入力パスも確認 |

再実行には[作業用preset](CMakePresets.json)を使う。検証buildは`build/cmake-features`、
install先は`install/cmake-features`の各preset名の下に保持した。計測データは各profile buildの
`instrumentation`に保持した。

日本語説明は目視で照合した。既存Python launcherが実行できず、`py`も見つからないため、
yomiyasuの自動検査は未実行。Linux・Emscripten/WASI実SDKの検証は今回も行っていない。

## presetの継承軸の整理

ホスト環境とtoolchainの指定を公開presetへ直接追加した構成を見直し、
TechDemoGameのstashで用いられていた独立したhidden presetの組み合わせを取り入れる。
stashの欠落したホストファイルや、OS設定に静的runtime等を混在させる方式は移さない。

### 実施順

1. 既存presetの設定と書式を確認する。
   - [x] 指定されたmasterのschemaから、version 13のフィールド順を確認。
   - [x] 変更前の通常・作業用presetを保存し、比較の基準を用意。
2. 継承軸を分離する。
   - [x] [継承軸のpreset](../../cmake/presets/CMakeProjectPresets.json)を明示的にinclude。
   - [x] ホスト条件・target/toolchain・generator・compiler・linkerをhidden presetへ移動。
   - [x] single/multi-configの構成設定とbuild/testの構成選択を分離。
   - [x] 機能の切り替えを独立させ、作業用presetにも接続。
   - [x] 機能の上書きを先に継承し、ホスト条件の競合を避ける。
3. 既存の利用方法と書式を維持する。
   - [x] 公開preset名とbuild/test/package/workflowの参照を維持。
   - [x] 日本語descriptionの既存文を維持し、追加分も現行の名詞句の様式で記述。
   - [x] `$comment`以外のフィールドをschema順へ並べ替え。
   - [x] 既存の空コメント・配列・オブジェクトを維持。rootのinclude配列だけは接続先を追加。
4. 検証と説明を更新する。
   - [x] schema・フィールド順・継承後の有効設定を比較。
   - [x] Windowsの3 compilerでDebug/Releaseを再configure/build/test。
   - [x] 計測presetと配布workflowを再確認。
   - [x] [README](../../src/README.md)に継承軸、優先順、条件と組み合わせの制約を記載。

### 検証結果

- 通常・作業用の変更前presetについて、継承後の設定の比較122件が一致した。
  BOOLの文字列表現と真偽値は同じ値として比較した。共通baseとsingle-configのSDK向けから
  `CMAKE_CONFIGURATION_TYPES`を除いた点だけは、意図した差として確認した。
- 3つのpresetファイルが指定されたschemaに適合し、フィールド順も一致した。
  並べ替えでは既存のインデント・改行・値の表記を保持した。
- WindowsでCMakeによる一覧表示を確認し、Linux/Darwinのホスト条件は継承した値で照合した。
  Linuxのnative構成はLinuxだけ、Windowsのnative構成はWindowsだけで利用できる条件を維持。
  SDK向けはホスト条件を付けず、Visual Studioの無効化も維持した。
- clang-cl・clang++・MSVCのDebug/Releaseでconfigure/build/CTest各7件が成功した。
- build/testの構成選択をすべて接続した最終状態でも、3 compilerのDebug/Releaseで
  CTest各7件が成功した。両Clang frontendの計測presetもconfigure/build/CTest各7件が成功した。
- 作業用の配布workflowが5段階すべて成功し、Release ZIP・SHA-256ファイルの生成と
  検査合計検証targetの実行を確認した。
- Linux・Emscripten/WASI実SDKのビルドは未検証。日本語説明は目視で確認し、
  yomiyasuの自動検査はPythonを実行できないため未実行。
  `yomiyasu-check: not_run reason=no_python`

## 独立した最小使用例で確認した分離課題

単一の`main.cpp`から`import std;`を使う独立した案件を作成した際に確認した。
最小化する対象は案件固有の実装であり、複数環境の構成、事前定義設定の分割、
workspace、構築・テスト・配布・デバッグの開発フローは保持する。
以下の課題について境界を相談し、元の基盤と独立例の両方を更新した。

- [x] Windows toolchainの案件固有の変数への依存を分離する。
  [Windows.cmake](../../cmake/toolchains/Windows.cmake)は
  標準変数`CMAKE_SYSTEM_PROCESSOR`を入力とし、案件変数を参照しない。
  案件別のarchitecture軸から、標的選択用の標準変数と案件の検証用変数を設定する。
  既存presetの動作は維持する。直接指定時に案件変数だけでは標的を選択しなくなる変更は合意済み。
  Clang target選択・native/cross判定・別名の受付を検証し、独立例へ同じファイルを複製した。

- [x] 配布の汎用処理と案件の成果物定義を分離する。
  [MyImportStdInstall.cmake](../../cmake/MyImportStdInstall.cmake)には、moduleのexportと
  package config生成と、配布形式・保存先・命名の採用値だけを残した。
  [汎用配布関数](../../cmake/generic-build-infrastructure/CxxGenericBuildInfrastructurePackaging.cmake)へ
  CPack設定生成・入力検証・SHA-256検証targetの登録を分離した。
  [検証スクリプト](../../cmake/generic-build-infrastructure/VerifyPackageChecksums.cmake)も同じ場所に移した。
  元案件と実行ファイルだけの独立例が、同じ汎用処理を使用する。

- [x] 事前定義設定に混在する再利用可能な接続と案件の採用値を整理する。
  [案件別事前定義設定](../../cmake/presets/CMakeProjectPresets.json)には、
  出力レイアウト・CPU要件・機能選択と、案件のキャッシュ変数への接続を残した。
  toolchain参照と操作軸は汎用側へ移し、toolchainのパスは`${sourceDir}/cmake/toolchains/...`とした。
  [ルート事前定義設定](../../CMakePresets.json)の環境別の組み合わせと公開構成は案件側に残すことで合意した。
  軸名と既存の構成・操作・workflowは維持し、案件別軸なしでもconfigureできる。
  当初の`${fileDir}`基準の参照はCMake本体では動作したが、CMake Tools 1.24.42が
  継承先の場所を基準に展開したため、IDE経由のconfigureに失敗した。
  このため、toolchainをソースルートの`cmake/toolchains`に置く標準配置へ変更した。
  事前定義設定を別の場所へ配置したfixtureでも、この標準配置のtoolchainが選択されることを検証する。
  修正後はCMake Tools経由のビルドと`my_import_std.preset_axes`が成功し、診断が解消した。

- [x] workspaceの再利用箇所と案件の参照箇所を区別して説明する。
  formatter・clangd・terminal・CMake Tools・launch設定と、表示フォルダー名・比較用フォルダー・
  名前付き`${workspaceFolder:...}`参照が同じファイルにあった。
  元workspaceのsource directory・compile databaseのコピー先・初期選択先は、
  workspace本体に`${workspaceFolder}`基準で記述する。
  これらを`.vscode/settings.json`へ移す方針は取り消した。
  workspace本体と開発フローは残し、VS Codeが提供しないincludeの仕組みは追加しない。
  再利用時の編集箇所はソース構成の説明と独立例のREADMEに記載した。

例側で省くのは、元案件の独自module・その利用例・ライブラリのexportと、
基盤自体を手直しするためのfixture・作業用資料である。
汎用CMakeモジュール、汎用事前定義設定、すべてのtoolchain、
formatter・clangd・フォルダー設定は内容を変更せず複製する。

分離後の検証では、元案件のclang-cl Debug/Releaseで関連6テストずつが成功した。
元案件と独立例の両方でZIP生成とSHA-256検証が成功し、独立例のDebug workflowも成功した。
配布関数は独立fixtureで正常動作・変数スコープ・7種類の不正入力を検証した。
Windows toolchainはnative/cross・processor別名・未指定・競合・不正値・ホスト条件、
SDK toolchainは委譲と不足時の診断を確認した。
元案件と独立例でclang++・MSVCのDebugビルドと実行テストも成功した。
元案件のRelease install後、別のconsumerからexportしたmoduleを利用できることを確認した。
既存188事前定義設定の実効設定をGit管理下の変更前と比較し、標準processor入力の追加と
同じtoolchainを指すパス表現の変更を除いて一致した。
Linux・AArch64・実SDKでのビルドとVS CodeのデバッガーUIは未検証。

## 利用者の好みと汎用処理の追加分離

- 色付き診断、configureのdebug/trace、インストール時の表示量、テスト失敗時の出力表示を、
  共有構成での選択から外した。利用者側のpresetで選択する。
- `CMakeUserPresets.json`はテンプレートとしてGitの追跡対象にする。
  入口には`cmake/presets/CMakeRecommendedUserPresets.json`のincludeを置き、推奨例を分離した。
  推奨例は共有presetを明示的にincludeする。共有側は利用者側のファイルに依存しない。
  Windows clang-clの主構成に対する個人用configure/build/test/workflowを用意した。
- 警告・エラー方針と言語規格、CPU要件、開発ツール用のcompile_commands出力は共有側に残した。
- CPU要件の検証・オプションへの変換、計測登録とcallback、出力先と静的ランタイムの適用を
  `cmake/generic-build-infrastructure/`へ分離した。案件側は採用値と対象を渡す。
- 出力先とランタイムは後続targetの初期値として適用する。既存の配置と適用時点を保つ。
- 汎用モジュールだけをincludeする検査と、個人用ファイルなしで共有presetを読む検査を追加した。

### 今回の検証

- Windows clang-clで共有構成のDebugビルドと関連CTest 5件が成功した。
- 個人用presetでDebug/Releaseをビルドし、各構成のmodule・app・preset検査3件が成功した。
- 個人用ファイルを含めずに共有presetの一覧を読み込めることを確認した。
- 新しい共有buildのキャッシュに個人の色・インストール表示設定がなく、個人用buildでは
  それらの設定が有効なことを確認した。traceも指定どおり生成された。
- 全CTest 7件では、未変更のchecksum検査とtoolchain検査が既存の診断文との不一致で失敗した。
  この2件は今回修正していないため、全テストを実行するworkflowも現状では失敗する。

## LLVM形式に倣ったpreset名

名前は単独の軸、基本設定、組み合わせ済みpreset、操作を区別する形式に変更した。
以前の実施記録の旧名は当時の名前として残し、現在の実行例はREADMEを更新した。

### 命名と移行

- [x] 単独の軸を`軸名:選択値`とし、`-`を部品間の区切り、`_`を部品内のスペースの代用にする。
- [x] 他の軸や適用方式への依存を`()`で示す。名前だけでは条件を適用しない。
- [x] 基本設定を`base:project`、組み合わせ済みの継承用設定を`bundle:*`に変更する。
- [x] Windowsの組み合わせ済みpresetは、確認した`x86_64-pc-windows-msvc`を先頭にし、
  driver・明示したlinker・generator・ビルド構成・機能を続ける。
  triple内部のLLVM表記はそのまま保持する。
- [x] 利用者の選択に従い、targetを固定していないLinux/SDK構成は
  `linux_native`・`Emscripten_sdk`・`WASI_sdk`と表し、architecture・ABIを推測で追加しない。
- [x] configure/workflow以外は操作接頭辞を付け、workflowはvalidation/distributionの目的名を使う。
- [x] 通常・作業用presetの継承、configure接続、workflowのstepを種類別に更新する。
  旧名のaliasは作らない。日本語description・コメント・空のプレースホルダーは維持する。
- [x] READMEの実行例とpresetテストを新名へ更新する。

### 出力先の分離（下記の「出力先統一とfixtureの隔離」で更新）

長い名前を`${configurePresetName}`で出力ディレクトリへ使うと、計測構成のnested testで
Windowsのパス長に関係するcompiler検証の失敗が起きた。
名前を短縮して命名規約を崩す代わりに、`layout:*`を出力先だけの独立した軸として導入した。
既存の各構成ではlayoutを先に継承し、従来の短いbuild・install・ZIP出力先を維持する。
layoutはcompiler・target・ビルド構成を選択せず、作業用layoutのcache設定も
`CPACK_PACKAGE_DIRECTORY`だけに限定している。

### 検証結果

- 変更前のpreset128件について、名前・参照・layoutの継承以外の設定が同じであることを確認した。
  具体的なconfigure構成の有効設定とbuild・install・ZIP出力先も維持した。
- 3つのJSONファイルが指定されたschemaに適合し、フィールド順も一致した。
  READMEのコマンドが正しい種類のpresetを参照することも確認した。
- 新名でWindowsのclang-cl・clang++・MSVC、Debug/Releaseの6構成をconfigure/buildし、
  CTest各8件が成功した。両Clang frontendの計測構成も各8件成功した。
- 新名の配布workflowが5段階すべて成功し、ZIP・SHA-256生成と検証を確認した。
  新名のinstall操作も従来の検証build先で成功した。
- Linux・実SDK・ASanの実ビルドは今回未検証。Windowsのtriple名は既定のx64 developer環境を
  表し、compilerのtargetを名前だけで固定する設定は追加していない。
- 日本語説明は目視で照合した。Pythonを実行できないため、自動文章検査は未実行。
  `yomiyasu-check: not_run reason=no_python`

## 再利用する開発基盤とプロジェクト設定の分離

汎用モジュールは別リポジトリからも直接includeできる構成を選択した。
プロジェクト名・cache変数・target名・出力レイアウト・toolchain pathを汎用側に持ち込まない。

### 実施項目

- [x] 共通compile設定とPDB helperを`cmake/generic-build-infrastructure/CxxGenericBuildInfrastructureTargets.cmake`へ分離。
- [x] CPU・architecture・AVX2・instrumentationの方針は`MyImportStdTargetSettings.cmake`に維持。
- [x] PDB出力先を利用側で明示し、プロジェクトの配置方針を汎用helperから除外。
- [x] generator・compiler・構成・診断等の軸を`CMakeGenericBuildInfrastructurePresets.json`へ分離。
- [x] toolchain file・CPU要件・project feature・layout等を`CMakeProjectPresets.json`へ分離。
- [x] ルートpresetと検査を更新し、汎用presetにプロジェクト固有変数がないことを検証。
- [x] READMEと作業計画を更新する。

### 分離後の責務

`CMakeLists.txt`にはproject定義・実target・適用するプロジェクト方針を残す。
汎用ビルド基盤のCMake target helperとpreset軸は独立してincludeできる。
`CMakeGenericBuildInfrastructurePresets.json`にはホストやcompilerなど、別のプロジェクトでも使える選択値を置く。
toolchainの場所、CPU要件、機能、build/install先はプロジェクト側で組み合わせる。

### 検証結果

- generic target helperだけをincludeするfixtureがconfigureに成功した。
- `cmake --list-presets`で、分割後のincludeを含むルートpresetを読み込めることを確認した。
- 新しいNinja Multi-Config build先でclang-clを使い、Debug/ReleaseのbuildとCTest各7件が成功した。
- CTestのpreset検査で、generic軸にproject変数やproject内パスが含まれないことを確認した。

## 直交軸の追加分離

当時の通常presetと継承軸presetを再確認し、残っていた設定の混在を分離した。
便宜presetは残し、単独の軸を定義するpresetには他の軸の設定を含めない。

### 実施項目

- [x] generatorから構成一覧の継承を外し、`ninja-multi-base`等で明示的に組み合わせる。
- [x] single-config用にDebug/Release/RelWithDebInfoの構成選択を用意する。
- [x] ASanのDebug用フラグとDebug限定の構成一覧を分離する。
  従来の複合preset名はルートへ移して維持する。
- [x] architecture/toolsetの指定を独立させ、準備用の`version=`と空コメントを保持する。
- [x] `project-base`を診断等を含まない共通設定として用意し、`common-base`は従来の
  診断・debug・traceを組み合わせる便宜presetとして維持する。
- [x] install・checksum・準備targetの操作とcompiler構成への接続を分離する。
- [x] test出力方針、package形式、package構成選択を独立させる。
- [x] 作業用presetの診断と準備操作も共有する軸へ接続する。
- [x] 軸の設定範囲とルートのconfigure構成を確認する
  [CTestスクリプト](../../tests/cmake/RunPresetChecks.cmake)を追加し、`BUILD_DEPENDS`を登録する。
- [x] 最終状態のschema順・有効設定・Windows統合検証を確認する。

異なる種類のpreset間の継承、複数の`condition`の自動AND、`targets`等のリストの自動結合は
CMakeが提供しないため、これらは軸を分離しても行えない。
組み合わせの制約をREADMEに記載し、任意のcompiler・SDK構成への対応を示すものとはしない。

### 追加分離の検証結果

- 変更前の通常・継承軸・作業用preset計105件について、有効設定と表示情報を比較した。
  2つのgenerator軸から構成一覧の自動指定を外した点だけを意図した差とし、
  既存の組み合わせ済みpresetはすべて同じ設定を維持した。
- 3つのJSONファイルが指定schemaに適合し、フィールド順も一致した。
  移動したtrace・architecture・toolsetのコメントを含め、既存のコメントと空の
  プレースホルダーの数と内容が変わらないことを確認した。
- `my_import_std.preset_axes`を含むCTest各8件が、Windowsのclang-cl・clang++・MSVC、
  Debug/Releaseの6構成で成功した。両Clang frontendの計測構成も各8件成功した。
- 配布workflowの5段階が成功し、Release ZIP・SHA-256ファイルの生成と検証を確認した。
- 作業用build先を明示し、通常の`install-clangcl-release` presetでinstall操作を実行した。
  Releaseの成果物と`MyImportStdConfig.cmake`の配置を確認した。
- ASanの継承設定は比較したが、今回ASanの実ビルドは行っていない。
  Linux・Emscripten/WASI実SDKのビルドも未検証。
- 日本語説明は目視で照合した。Pythonを実行できないため、自動文章検査は未実行。
  `yomiyasu-check: not_run reason=no_python`

## 配布工程の独立化

上記の配布関数・専用configureに関する記録は、この変更で更新した。

- 通常configureはビルド情報と薄い`DistributionConfig.cmake`、明示実行用のchecksum targetだけを登録する。
  `include(CPack)`・配布専用ツールの探索・配布設定の検証は実行しない。
- [独立entry](../../cmake/generic-build-infrastructure/CPackConfig.cmake)はCPack実行時に情報を読み取り、
  package presetの採用値を適用後に検証する。生成済みのinstallスクリプトを使い、ビルドを起動しない。
- 配布専用configure・案件の`*_ENABLE_PACKAGING`・`feature:Packaging`を撤去した。
  通常のRelease構成から配布し、configure→build→test→package→checksumの順序はworkflowが担う。
- CMake 4.5.0-rc1の`configFile`継承不足とCMake Tools 1.24.42のパスマクロ展開の制約を実測した。
  各package presetにbuild先基準の固定名を直接指定し、通常構成・利用者構成・任意のbuild先に接続する。
- 独立fixtureで単独配布・全5段階workflow・single/multi-config・複数構成の同梱・
  成果物不足・ビルドの非実行・出力先/名前/構成の入力検証・ZIP内容・SHA-256を確認した。
- 基盤本体の関連6テスト、Release ZIPとmodule/exportの配置、SHA-256検証が成功した。
  ZIPを展開した別のconsumerから`find_package(MyImportStd)`・moduleのimport・実行にも成功した。
  独立例の配布workflowと利用者Debug workflowも成功した。
- 基盤本体の全体workflowは、既存toolchainテストの期待する診断文
  「対応なされていない値です」と実装の「サポートされていない値です」の不一致で停止する。
  今回は変更しない。CMake Toolsの実行確認もactive configure presetがなく実施できず、
  元TypeScriptの引数・環境・作業ディレクトリと、同等のCPack操作を照合した。

## 出力先統一とfixtureの隔離

上記のlayoutによるパス長回避策を、原因への対応に置き換えた。

- 未指定のpreset名要素を既存の名前・参照・説明も含め`*`から`@`へ変更した。
  基盤と独立使用例の全presetファイル、計308件の名前に旧表記とlayout定義がないことを確認した。
- 案件のlayout 15件と検証用layout 5件を撤去した。利用者設定の保存先上書きも撤去し、
  `build/${presetName}`・`install/${presetName}`を共通規則にした。
- 成果物・PDBの出力先と言語方針は`base:project`で宣言する。
  target側の重複設定を撤去したが、exportするmoduleの`PUBLIC cxx_std_23`と再利用用helperは維持した。
- 旧構造では、長い計測用build先の下にhelper fixtureを置くと、compiler確認の
  objectディレクトリが264文字になり、Ninjaのmkdir失敗を再現できた。
  fixtureは`build/.checks/<build先のSHA-256先頭16桁>/<構成>/`へ切り離し、テスト別に分けた。
  preset検査は実際のCTest登録を読み、6つのscriptテストの分離も確認する。
- 作業用ZIPとchecksumには、build先基準の相対値`CGBI_PACKAGE_DIRECTORY=packages`を使う。
  相対指定への対応は汎用entryと検証スクリプトへ追加し、独立使用例にも反映した。
  空の環境値は拒否し、直接指定する`CPACK_PACKAGE_DIRECTORY`の絶対パス要件は維持した。
  CMake Tools 1.24.42の元TypeScriptでは`${configurePresetName}`の展開がなく、
  CLIでは継承環境内の`${presetName}`が操作preset名として再展開されたため、どちらにも依存しない。

### 検証結果

- 基盤の正式な長名build先でReleaseの関連7テストが成功した。
  最長のclang-cl計測用presetでもDebugの関連8テストが成功し、fixture隔離の追加検査も通った。
- clang++ Release・MSVC Debugのビルドとmodule/app/example/presetの各4テストが成功した。
  DebugのPDBは構成別のbinへ出力された。
- 通常・検証用のinstall準備、ZIP生成、SHA-256検証が成功した。
  install先を参照する独立consumerでC++23の伝播、moduleのimport、ビルド・実行を確認した。
- 配布fixtureは絶対指定・空白を含む相対指定・空値拒否を確認し、
  新しい検証用build先への配布とchecksumも成功した。
- 独立使用例の配布workflow全5段階、利用者Debug workflow、相対配布先の生成・検証が成功した。
  汎用モジュール9件とtoolchain 4件は両リポジトリで同一である。
- 既知のtoolchainテストの診断文不一致は別件として変更せず、関連スイートから除外した。
  Linux・実SDK・IDE上の実操作は今回未検証である。既存のbuild/install成果物は削除・移動していない。
