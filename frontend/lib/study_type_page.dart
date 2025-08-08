import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // 막대그래프용

class StudyTypePage extends StatelessWidget {
  const StudyTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학습 유형 분석'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마이페이지에서 학습 유형 분석하기 버튼 → 학습 유형 페이지',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // 분석 요약 카드
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _SummaryCard(
                  title: '고성실도',
                  subtitle: '성실도 지수',
                  color: Color(0xFFE8E6FA),
                ),
                _SummaryCard(
                  title: '복습형',
                  subtitle: '학습 유형',
                  color: Color(0xFFE6F9ED),
                ),
                _SummaryCard(
                  title: '오전',
                  subtitle: '학습 시간대',
                  color: Color(0xFFFFF5D6),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 요일별 시간 분석 (Bar chart)
            const Text(
              '요일별 시간 분석',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const days = [
                            'MON',
                            'TUE',
                            'WED',
                            'THU',
                            'FRI',
                            'SAT',
                            'SUN',
                          ];
                          return Text(
                            days[value.toInt() % 7],
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (index) {
                    final heights = [
                      3.0,
                      4.0,
                      5.0,
                      6.0,
                      7.0,
                      6.5,
                      7.5,
                    ]; // 샘플 데이터
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: heights[index],
                          color: Colors.grey,
                          width: 16,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 설명 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌞 아침 루틴러',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '꾸준히 챙겼음을 떠올리는 타입!\n오전 집중력이 높은 당신, 아침 계획을 잘 활용해보세요.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 버튼들
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 분석하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download),
                  label: const Text('이미지 저장하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 데이터 부족 안내
            Center(
              child: Column(
                children: const [
                  Icon(Icons.visibility_off, size: 30, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('일주일 뒤에 가능합니다!', style: TextStyle(color: Colors.grey)),
                  Text(
                    '데이터가 조금 더 쌓여야 해요.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 분석 요약 카드 위젯
class _SummaryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 70,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
