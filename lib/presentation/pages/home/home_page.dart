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

final openAI = OpenAIService();

class GPTDemoPage extends StatefulWidget {
  const GPTDemoPage({super.key});

  @override
  State<GPTDemoPage> createState() => _GPTDemoPageState();
}

class _GPTDemoPageState extends State<GPTDemoPage> {
  final TextEditingController _controller = TextEditingController();
  String _responseText = "";
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final userInput = _controller.text.trim();
    if (userInput.isEmpty) return;

    setState(() {
      _isLoading = true;
      _responseText = "";
    });

    try {
      final reply = await openAI.chatWithGPT(userInput);
      setState(() {
        _responseText = reply;
      });
    } catch (e) {
      setState(() {
        _responseText = "에러 발생: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GPT API Demo")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "메시지 입력",
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendMessage,
              child: const Text("GPT에게 보내기"),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _responseText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
