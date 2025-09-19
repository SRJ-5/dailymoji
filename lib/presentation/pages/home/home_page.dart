import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  final Dio _dio = Dio();
  final String apiKey = dotenv.env['GPT_API_KEY'] ?? '';

  Future<String> chatWithGPT(String userMessage) async {
    const String url = "https://api.openai.com/v1/chat/completions";

    try {
      final response = await _dio.post(
        url,
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $apiKey",
          },
        ),
        data: {
          "model": "gpt-4o-mini", // 또는 gpt-4o, gpt-4.1 등
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": userMessage}
          ],
          "max_tokens": 200,
        },
      );

      if (response.statusCode == 200) {
        final reply = response.data['choices'][0]['message']['content'];
        return reply;
      } else {
        throw Exception("응답 실패: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Dio 요청 에러: $e");
    }
  }
}

// final openAI = OpenAIService();

// class GPTDemoPage extends StatefulWidget {
//   const GPTDemoPage({super.key});

//   @override
//   State<GPTDemoPage> createState() => _GPTDemoPageState();
// }

// class _GPTDemoPageState extends State<GPTDemoPage> {
//   final TextEditingController _controller = TextEditingController();
//   String _responseText = "";
//   bool _isLoading = false;

//   Future<void> _sendMessage() async {
//     final userInput = _controller.text.trim();
//     if (userInput.isEmpty) return;

//     setState(() {
//       _isLoading = true;
//       _responseText = "";
//     });

//     try {
//       final reply = await openAI.chatWithGPT(userInput);
//       setState(() {
//         _responseText = reply;
//       });
//     } catch (e) {
//       setState(() {
//         _responseText = "에러 발생: $e";
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(title: const Text("GPT API Demo")),
//     body: Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           TextField(
//             controller: _controller,
//             decoration: const InputDecoration(
//               border: OutlineInputBorder(),
//               labelText: "메시지 입력",
//             ),
//           ),
//           const SizedBox(height: 12),
//           ElevatedButton(
//             onPressed: _isLoading ? null : _sendMessage,
//             child: const Text("GPT에게 보내기"),
//           ),
//           const SizedBox(height: 20),
//           _isLoading
//               ? const CircularProgressIndicator()
//               : Expanded(
//                   child: SingleChildScrollView(
//                     child: Text(
//                       _responseText,
//                       style: const TextStyle(fontSize: 16),
//                     ),
//                   ),
//                 ),
//         ],
//       ),
//     ),
//   );
// }

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          "assets/images/logo.png", // DailyMoji 로고 이미지 경로
          height: 30,
        ),
      ),

      // ✅ Body
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 말풍선
            Stack(
              children: [
                Image.asset("assets/images/Bubble 1.png"),
                Text(
                  "수니수니님, 오늘 왜 슬펐나요?",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(2, 2))
                ],
              ),
              child: const Text(
                "수니수니님,\n오늘 왜 슬펐나요?",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            // 캐릭터 이미지
            Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    "assets/images/cado_00.png", // 중앙 캐릭터 이미지
                    height: 180,
                    width: 120,
                  ),

                  // ✅ 감정 이모티콘들 (Stack + Positioned)
                  Positioned(
                    bottom: -100,
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_angry_02.png",
                      height: 80,
                    ),
                  ),
                  Positioned(
                    top: -60,
                    right: -90,
                    child: Image.asset(
                      "assets/images/emoticon/emo_3d_crying_02.png",
                      height: 80,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -110,
                    child: Image.asset(
                        "assets/images/emoticon/emo_3d_shocked_02.png",
                        height: 50),
                  ),
                  Positioned(
                    bottom: 20,
                    right: -110,
                    child: Image.asset(
                        "assets/images/emoticon/emo_3d_sleeping_02.png",
                        height: 50),
                  ),
                  Positioned(
                    top: -60,
                    left: -90,
                    child: Image.asset(
                        "assets/images/emoticon/emo_3d_smile_02.png",
                        height: 50),
                  ),
                ]),
          ],
        ),
      ),

      // ✅ BottomNavigationBar
      bottomNavigationBar: Stack(
        children: [
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "홈"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart), label: "보고서"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "마이"),
            ],
          ),

          // ✅ 채팅 입력창 버튼 (네비게이터 위에 고정)
          Positioned(
            left: 16,
            right: 16,
            bottom: 60, // BottomNav 위에 띄우기
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "무엇이든 입력하세요",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  Icon(Icons.send, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
