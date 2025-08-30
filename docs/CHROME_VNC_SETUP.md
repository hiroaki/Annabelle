# 開発用ブラウザ/VNC 手順の分割（旧版の案内）

このドキュメントは旧版です。手順は用途別に 2 本へ分割しました：

- ブラウザのみ（RSpec 向け、ヘッドレス想定）：`docs/BROWSER_SETUP.md`
- VNC（GUI でブラウザ操作、任意）：`docs/VNC_SETUP.md`

Chrome/Chromium は RSpec（cuprite）で必須ですが、VNC はデバッグ時のみ必要なオプションです。そのため、導入を分けて必要な方のみ行えるようにしました。

旧スクリプト `scripts/install_chromium_vnc.sh` は廃止方向です。以下の新スクリプトを利用してください：

- ブラウザ: `scripts/browser-install-chromium.sh`
- VNC: `scripts/vnc-install-tigervnc.sh`

詳細な手順、背景、トラブルシュートは分割先の各ドキュメントを参照してください。
