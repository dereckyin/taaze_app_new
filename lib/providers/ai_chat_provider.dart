import 'package:flutter/foundation.dart';
import '../screens/ai_chat_screen.dart';

class AiChatProvider with ChangeNotifier {
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  // 模擬AI回應的知識庫
  final Map<String, String> _knowledgeBase = {
    '推薦': '''
我來為你推薦一些優秀的書籍：

📚 **程式設計類**
• 《Clean Code》- 程式碼品質的經典之作
• 《設計模式》- 軟體設計的必讀經典
• 《演算法導論》- 演算法學習的權威教材

🎨 **設計類**
• 《設計心理學》- 了解用戶心理的設計指南
• 《色彩設計學》- 色彩搭配的專業知識

🤖 **人工智慧類**
• 《機器學習實戰》- 實用的ML入門書籍
• 《深度學習》- AI領域的經典教材

這些書籍在我們的書店都有庫存，你可以點擊查看詳細資訊！
''',
    '書籍': '''
我們書店有豐富的書籍選擇：

📖 **熱門分類**
• 程式設計與軟體開發
• 設計與藝術
• 人工智慧與機器學習
• 資料庫與網路安全
• 雲端運算與區塊鏈

🔍 **如何找到想要的書**
1. 使用搜尋功能輸入關鍵字
2. 瀏覽首頁的推薦分類
3. 查看暢銷排行榜
4. 關注新書上架

需要我幫你推薦特定類型的書籍嗎？
''',
    '價格': '''
關於書籍價格：

💰 **價格範圍**
• 新書：\$200 - \$800
• 二手書：\$100 - \$400
• 特價書籍：\$150 - \$500

🎯 **優惠活動**
• 新會員首次購書享8折優惠
• 滿\$500免運費
• 定期舉辦特價活動

💡 **省錢小貼士**
1. 關注今日特惠區
2. 查看二手書選項
3. 註冊會員享受優惠
4. 關注我們的促銷活動

需要我幫你找特定價格範圍的書籍嗎？
''',
    '運費': '''
關於運費說明：

🚚 **運費標準**
• 一般配送：\$60
• 快速配送：\$100
• 超商取貨：\$30

🎁 **免運條件**
• 購物滿\$500即可免運費
• 會員生日當月免運
• 特殊活動期間免運

📍 **配送範圍**
• 全台本島
• 離島地區（運費另計）
• 海外配送（需聯繫客服）

⏰ **配送時間**
• 一般配送：3-5個工作天
• 快速配送：1-2個工作天
• 超商取貨：2-3個工作天

有任何配送問題都可以詢問我！
''',
    '會員': '''
關於會員制度：

👤 **會員福利**
• 新會員首次購書8折優惠
• 生日當月免運費
• 專屬會員價格
• 優先獲得新書資訊
• 積分回饋制度

📝 **註冊方式**
1. 點擊首頁的「註冊」按鈕
2. 填寫基本資料
3. 驗證電子郵件
4. 立即享受會員優惠

🎯 **積分制度**
• 每消費\$100獲得1積分
• 100積分可折抵\$10
• 積分永久有效

💎 **VIP會員**
• 消費滿\$10,000自動升級
• 享受更多專屬優惠
• 專屬客服通道

需要我協助你註冊會員嗎？
''',
  };

  void sendMessage(String userMessage) {
    // 添加用戶訊息
    _messages.add(
      ChatMessage(
        content: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    // 模擬AI處理時間
    _isLoading = true;
    notifyListeners();

    // 延遲回應，模擬AI思考時間
    Future.delayed(const Duration(milliseconds: 1500), () {
      _generateAiResponse(userMessage);
    });
  }

  void sendImageMessage(String imagePath) {
    // 添加用戶圖片訊息
    _messages.add(
      ChatMessage(
        content: '我上傳了一張圖片',
        isUser: true,
        timestamp: DateTime.now(),
        imagePath: imagePath,
      ),
    );
    notifyListeners();

    // 模擬AI處理時間
    _isLoading = true;
    notifyListeners();

    // 延遲回應，模擬AI分析圖片時間
    Future.delayed(const Duration(milliseconds: 2000), () {
      _generateImageResponse(imagePath);
    });
  }

  void _generateAiResponse(String userMessage) {
    String aiResponse = _getAiResponse(userMessage);

    _messages.add(
      ChatMessage(
        content: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );

    _isLoading = false;
    notifyListeners();
  }

  void _generateImageResponse(String imagePath) {
    // 模擬AI分析圖片的回應
    final responses = [
      '''我看到了你上傳的圖片！📸

雖然我無法直接分析圖片內容，但我可以根據你的描述來幫助你：

• 如果是書籍封面，我可以幫你推薦類似的書籍
• 如果是條碼，我可以協助你搜尋相關書籍
• 如果是其他內容，請告訴我你想了解什麼

請描述一下圖片內容，我會盡力幫助你！''',

      '''感謝你分享的圖片！🖼️

我注意到你上傳了一張圖片。雖然我目前無法直接識別圖片內容，但我可以：

• 根據你的描述推薦相關書籍
• 協助你搜尋特定主題的書籍
• 回答關於書籍的問題

請告訴我圖片中是什麼，或者你想了解什麼，我會為你提供幫助！''',

      '''我看到你上傳了一張圖片！📷

很抱歉，我目前無法直接分析圖片內容，但我可以：

• 根據你的文字描述提供書籍推薦
• 協助你找到想要的書籍
• 回答關於購物和書籍的問題

請用文字描述一下圖片內容，或者告訴我你想了解什麼，我會盡力幫助你！''',
    ];

    final response = responses[DateTime.now().millisecond % responses.length];

    _messages.add(
      ChatMessage(content: response, isUser: false, timestamp: DateTime.now()),
    );

    _isLoading = false;
    notifyListeners();
  }

  String _getAiResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    // 根據關鍵字匹配回應
    if (message.contains('推薦') || message.contains('建議')) {
      return _knowledgeBase['推薦'] ?? _getDefaultResponse();
    } else if (message.contains('書籍') || message.contains('書')) {
      return _knowledgeBase['書籍'] ?? _getDefaultResponse();
    } else if (message.contains('價格') ||
        message.contains('多少錢') ||
        message.contains('價錢')) {
      return _knowledgeBase['價格'] ?? _getDefaultResponse();
    } else if (message.contains('運費') ||
        message.contains('配送') ||
        message.contains('寄送')) {
      return _knowledgeBase['運費'] ?? _getDefaultResponse();
    } else if (message.contains('會員') ||
        message.contains('註冊') ||
        message.contains('登入')) {
      return _knowledgeBase['會員'] ?? _getDefaultResponse();
    } else if (message.contains('你好') ||
        message.contains('hi') ||
        message.contains('hello')) {
      return '''你好！我是讀冊生活網路書店的AI智能助手 🤖

我可以幫你：
• 推薦適合的書籍
• 解答購物相關問題
• 提供會員服務資訊
• 協助你找到想要的書籍

有什麼我可以幫助你的嗎？''';
    } else if (message.contains('謝謝') || message.contains('感謝')) {
      return '''不客氣！很高興能幫助到你 😊

如果還有其他問題，隨時都可以問我！
祝你在讀冊生活找到心儀的書籍！''';
    } else {
      return _getDefaultResponse();
    }
  }

  String _getDefaultResponse() {
    final responses = [
      '''我理解你的問題，但可能需要更多資訊來幫助你。

你可以試試問我：
• "推薦一些程式設計的書籍"
• "書籍價格是多少？"
• "如何註冊會員？"
• "運費怎麼計算？"

或者告訴我你具體想了解什麼，我會盡力幫助你！''',

      '''這是一個很好的問題！讓我為你提供一些建議：

📚 你可以：
1. 瀏覽首頁的推薦分類
2. 使用搜尋功能找書
3. 查看暢銷排行榜
4. 關注新書上架

需要我幫你推薦特定類型的書籍嗎？''',

      '''我還在學習中，可能無法完全理解你的問題。

不過我可以幫你：
• 推薦書籍
• 解答購物問題
• 提供服務資訊

請試試用更簡單的方式問我，或者告訴我你想了解什麼！''',
    ];

    return responses[DateTime.now().millisecond % responses.length];
  }

  void clearChat() {
    _messages.clear();
    _isLoading = false;
    notifyListeners();
  }

  // 添加預設歡迎訊息
  void addWelcomeMessage() {
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          content: '''歡迎來到讀冊生活網路書店！我是你的AI智能助手 🤖

我可以幫你：
• 📚 推薦適合的書籍
• 💰 解答價格和優惠問題
• 🚚 提供配送資訊
• 👤 協助會員服務
• 🔍 幫你找到想要的書籍

有什麼我可以幫助你的嗎？''',
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }
}
