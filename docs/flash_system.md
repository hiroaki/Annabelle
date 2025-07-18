# 統合Flash メッセージシステム

## 概要

このシステムは、サーバーサイドとクライアントサイドの両方でFlashメッセージを統一して管理します。

## 機能

### サーバーサイド既存機能
既存の`flash[:alert]`、`flash[:notice]`は引き続き動作し、自動的に統合システムに移行されます。

### クライアントサイドAPI

```javascript
// 新しいFlashメッセージを表示
Flash.alert('エラーメッセージ');
Flash.notice('成功メッセージ');
Flash.warning('警告メッセージ');

// 全てのFlashメッセージをクリア
Flash.clear();

// オプション付きでメッセージを表示
Flash.alert('メッセージ', {
  autoDismiss: false,  // 自動消去を無効化
  delay: 10000,        // 10秒後に消去
  id: 'custom-id'      // カスタムID
});
```

### Turboイベント対応

以下のイベントで自動的にエラーメッセージが表示されます：

- `turbo:submit-end` - フォーム送信エラー
- `turbo:fetch-request-error` - ネットワークエラー、プロキシエラー
- `turbo:frame-missing` - フレーム読み込みエラー

### HTTPステータスコード対応

各HTTPステータスコードに応じた適切なメッセージが表示されます：

- 400: Invalid request. Please check your input.
- 401: You are not authorized to perform this action.
- 403: Access forbidden. You may need to confirm your email.
- 404: The requested resource was not found.
- 422: The submitted data is invalid.
- 500: A server error occurred. Please try again later.
- 502, 503: Service temporarily unavailable.
- 504: Request timeout. Please try again.

### アクセシビリティ

- `role="alert"` 属性でスクリーンリーダー対応
- `aria-live="polite"` で適切な読み上げ
- キーボードナビゲーション対応

### アニメーション

- メッセージ表示時の滑らかなアニメーション
- 自動消去時のフェードアウト
- 手動閉じるボタンでの即座の削除

## 使用例

### サーバーサイド（既存通り）
```ruby
flash[:alert] = "エラーが発生しました"
flash[:notice] = "正常に保存されました"
```

### クライアントサイド（新機能）
```javascript
// ネットワークエラー時
document.addEventListener('turbo:fetch-request-error', (event) => {
  // 自動的に適切なエラーメッセージが表示される
});

// 手動でメッセージ追加
Flash.alert('カスタムエラーメッセージ');
```

## 今後の拡張

- i18n-js による多言語対応準備済み
- UIアニメーションの強化可能
- カスタムスタイリング対応
- 複数メッセージタイプの追加