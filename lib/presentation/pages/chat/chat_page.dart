import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  EmotionalRecordDto? record;
  bool loading = false;

  Future<void> _sendCheckin() async {
    setState(() => loading = true);
    try {
      final url = "${getBaseUrl()}/checkin";
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": _controller.text,
          "intensity": 6,
          "contexts": ["home", "night"],
          "timestamp": DateTime.now().toIso8601String(),
          "surveys": {"phq9": 8, "gad7": 6, "psqi": 10},
        }),
      );

      final json = jsonDecode(response.body);
      setState(() {
        record = EmotionalRecordDto.fromJson(json);
      });

      // 로그 출력
      debugPrint("🔥 최종 클러스터 점수: ${record?.scorePerCluster}");
      debugPrint("🔥 g_score: ${record?.gScore}");
      debugPrint("🔥 profile: ${record?.profile}");
      debugPrint("🔥 추천 개입 preset: ${record?.intervention?["preset_id"]}");
      debugPrint("🪵 debug_log: ${record?.debugLog}");
    } catch (e) {
      debugPrint("API 호출 실패: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SRJ-5 Chat Test")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "텍스트 입력"),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : _sendCheckin,
              child: Text(loading ? "분석 중..." : "분석하기"),
            ),
            const SizedBox(height: 20),
            if (record != null) ...[
              Text("G-score: ${record!.gScore}"),
              Text("Profile: P${record!.profile}"),
              Text("추천 Intervention: ${record!.intervention?["preset_id"]}"),
              const Divider(),
              Text("중간 로그:",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent("  ")
                        .convert(record!.debugLog),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
