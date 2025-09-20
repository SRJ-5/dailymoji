import 'dart:convert';
import 'package:dailymoji/core/config/api_config.dart';
import 'package:dailymoji/data/dtos/emotional_record_dto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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

  /// 프로필 → 텍스트 라벨링
  String profileLabel(int profile) {
    switch (profile) {
      case 1:
        return "⚠️ 위기 수준 (심각)";
      case 2:
        return "😟 중등도 불안/우울";
      case 3:
        return "🙂 경미한 감정 기복";
      default:
        return "🟢 안정 상태";
    }
  }

  /// Bar Chart 데이터 변환
  List<BarChartGroupData> _buildBarGroups(Map<String, dynamic> scores) {
    final keys = scores.keys.toList();
    return List.generate(keys.length, (i) {
      final value = (scores[keys[i]] as num).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        // showingTooltipIndicators: [0],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scores = record?.scorePerCluster ?? {};
    final gScore = record?.gScore ?? 0.0;
    final profile = record?.profile ?? 0;
    final evidence =
        record?.debugLog?["llm"]?["evidence_spans"] as Map<String, dynamic>? ??
            {};
    final debugLog = record?.debugLog ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text("SRJ-5 감정 분석")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 입력창
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: "오늘 기분을 입력하세요"),
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
              // summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("총점(G-score): ${(gScore * 100).toInt()}%"),
                    Text("프로필: ${profileLabel(profile)}"),
                    Text(
                        "추천 Intervention: ${record!.intervention?["preset_id"]}"),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Bar Chart
              SizedBox(
                height: 250,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 1.0, // 점수는 0~1 범위
                    barGroups: _buildBarGroups(scores),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles:
                            SideTitles(showTitles: true, reservedSize: 28),
                      ),
                      rightTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:
                          AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final keys = scores.keys.toList();
                            if (value.toInt() < 0 ||
                                value.toInt() >= keys.length) {
                              return const SizedBox.shrink();
                            }
                            return Text(keys[value.toInt()]);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Evidence spans → Chip
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: evidence.entries.expand((entry) {
                  final cluster = entry.key;
                  final words = entry.value as List<dynamic>;
                  return words
                      .map((word) => Chip(label: Text("$word ($cluster)")))
                      .toList();
                }).toList(),
              ),
              const Divider(),

              // Debug Log (전체 JSON pretty print)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent("  ").convert(debugLog),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
