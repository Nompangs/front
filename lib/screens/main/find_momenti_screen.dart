import 'package:flutter/material.dart';

class FindMomentiScreen extends StatelessWidget {
  const FindMomentiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E9),
      body: SafeArea(
        child: Stack(
          children: [
            // 지도 배경 (회색+흰색 블록)
            Positioned.fill(
              child: Container(
                color: Colors.white,
                child: CustomPaint(painter: _MapGridPainter()),
              ),
            ),
            // 상단 앱바
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFDF7E9),
                      Color(0xFFFDF7E9).withOpacity(0.0),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '모멘티 찾기',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // 오른쪽 여백
                  ],
                ),
              ),
            ),
            // 검색바
            Positioned(
              top: 64,
              left: 16,
              right: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.black54),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '정자동',
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                    Icon(Icons.edit, color: Colors.black38),
                  ],
                ),
              ),
            ),
            // 정렬/필터/결과수
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  _FilterChip(label: '거리순', selected: true),
                  SizedBox(width: 8),
                  _FilterChip(label: '소유자', selected: true),
                  Spacer(),
                  Text(
                    '39 results',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            // 해시태그 마커들
            _buildHashtagMarkers(width, height),
            // 하단 카드
            Align(
              alignment: Alignment.bottomCenter,
              child: _BottomMomentiCard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagMarkers(double width, double height) {
    // 실제 앱에서는 위치값을 데이터로 관리해야 함
    return Stack(
      children: [
        _HashtagMarker(label: '#마이펫', left: 40, top: 180),
        _HashtagMarker(
          label: '#분당 영쿠션',
          left: width / 2 - 60,
          top: 220,
          isMain: true,
        ),
        _HashtagMarker(label: '#창원김씨', left: width - 120, top: 160),
        _HashtagMarker(label: '#춘자', left: width / 2 - 20, top: 300),
        _HashtagMarker(label: '#김봉봉', left: width - 100, top: 260),
      ],
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.fill;
    // 배경
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    // 격자
    final gridPaint =
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HashtagMarker extends StatelessWidget {
  final String label;
  final double left;
  final double top;
  final bool isMain;
  const _HashtagMarker({
    required this.label,
    required this.left,
    required this.top,
    this.isMain = false,
  });
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isMain ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isMain ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _FilterChip({required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? Color(0xFFFDF7E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _BottomMomentiCard extends StatelessWidget {
  const _BottomMomentiCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8, left: 8, right: 8),
      padding: EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Color(0xFFFFA726),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Center(
              child: Image.asset(
                'assets/ui_assets/cushion.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '분당 영쿠션',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.black45),
                    SizedBox(width: 4),
                    Text('@nompangs', style: TextStyle(color: Colors.black54)),
                    SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: Colors.black45),
                    SizedBox(width: 4),
                    Text('1.2 km', style: TextStyle(color: Colors.black54)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '1.3',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text('천 구독자', style: TextStyle(color: Colors.black54)),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      child: Text('더보기', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}
