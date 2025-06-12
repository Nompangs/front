import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Momenti App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Pretendard',
      ),
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String selectedFilter = "전체";
  final List<String> filterOptions = ["전체", "내 방", "우리집 안방", "사무실", "단골 카페"];

  final List<ObjectData> objectData = [
    ObjectData(
      title: "디자인 체어",
      location: "내 방",
      duration: "42 min",
      isNew: true,
      imageUrl: "https://images.pexels.com/photos/343871/pexels-photo-343871.jpeg",
    ),
    ObjectData(
      title: "제임쓰 카페인쓰",
      location: "사무실",
      duration: "5 min",
      imageUrl: "https://images.pexels.com/photos/17486823/pexels-photo-17486823.jpeg",
    ),
    ObjectData(
      title: "빈백",
      location: "우리집 안방",
      duration: "139 min",
      imageUrl: "https://images.pexels.com/photos/32372040/pexels-photo-32372040.png",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final isPortrait = height > width;
    final baseWidth = 375.0;
    final scale = width / baseWidth;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 25, 25),
      body: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 123, 0, 255),
          borderRadius: BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Column(
            children: [
              // Header with cream background (높이 240)
              Container(
                width: double.infinity,
                height: 240 * scale,
                color: const Color(0xFFFDF7E9),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 24 * scale, top: 60 * scale, bottom: 32 * scale, right: 8 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '오늘, 2025년 06월 04일',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14 * scale,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 24 * scale),
                            Text(
                              '안녕하세요, 씅님',
                              style: TextStyle(
                                color: Color(0xFF222222),
                                fontSize: 30 * scale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12 * scale),
                            Text(
                              '오늘은 누구랑 대화할까요?',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 20 * scale,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 60 * scale, right: 32 * scale),
                      child: Container(
                        width: 64 * scale,
                        height: 64 * scale,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32 * scale),
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.green[400]!, Colors.yellow[400]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: Colors.white),
                        ),
                        child: Center(
                          child: Text('🧑‍💼', style: TextStyle(fontSize: 32 * scale)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Yellow notification bar
              Transform.translate(
                offset: Offset(0, -29 * scale),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 24 * scale),
                  height: 48 * scale,
                  decoration: BoxDecoration(
                    color: Color(0xFFFFEB3B),
                    borderRadius: BorderRadius.circular(40 * scale),
                    border: Border.all(color: Colors.black),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 45 * scale),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14 * scale,
                            ),
                            children: [
                              TextSpan(
                                text: '털찐 말랑이',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: '와 최근 마지막으로 대화했어요.',
                                style: TextStyle(fontWeight: FontWeight.w300),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 45 * scale,
                        height: 44 * scale,
                        margin: EdgeInsets.only(right: 1 * scale),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22 * scale),
                        ),
                        child: Center(
                          child: Transform.rotate(
                            angle: -0.785398, // -45 degrees
                            child: Icon(Icons.arrow_upward, size: 16 * scale, color: Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              


              // 파랑/핑크/초록 타원 버튼 영역 (가로 스크롤 없이 화면에 꽉 차게 겹침)
              Container(
                width: double.infinity,
                color: Colors.black,
                height: 130 * scale,
                alignment: Alignment.center,
                child: Builder(
                  builder: (context) {
                    final overlap = 0 * scale;
                    final buttonWidth = 100 * scale;
                    final buttonHeight = 170 * scale;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 첫 번째 버튼 (파랑)
                        Transform.rotate(
                          angle: -45 * 3.141592 / 180,
                          child: ClipOval(
                            child: Container(
                              width: buttonWidth,
                              height: buttonHeight,
                                color: Color(0xFF4DB6FF),
                              child: Center(
                                child: Transform.rotate(
                                  angle: 45 * 3.141592 / 180,
                                child: Text(
                                  '나와\n접촉한 모멘티',
                                  style: TextStyle(
                                    color: Colors.white,
                                      fontSize: 16 * scale,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 두 번째 버튼 (핑크, 왼쪽으로 overlap만큼 겹침)
                        Transform.translate(
                          offset: Offset(-overlap, 0),
                          child: Transform.rotate(
                            angle: -45 * 3.141592 / 180,
                            child: ClipOval(
                            child: Container(
                                width: buttonWidth,
                                height: buttonHeight,
                                color: Color(0xFFFFB6D5),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 45 * 3.141592 / 180,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '새로운',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '모멘티 깨우기',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Text(
                                          '+',
                                  style: TextStyle(
                                    color: Colors.white,
                                            fontSize: 24 * scale,
                                    fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 세 번째 버튼 (초록, 왼쪽으로 overlap만큼 겹침)
                        Transform.translate(
                          offset: Offset(-overlap, 0),
                          child: Transform.rotate(
                            angle: -45 * 3.141592 / 180,
                            child: ClipOval(
                            child: Container(
                                width: buttonWidth,
                                height: buttonHeight,
                                color: Color(0xFF4DEB8A),
                                child: Center(
                                  child: Transform.rotate(
                                    angle: 45 * 3.141592 / 180,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '내 주변',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16 * scale,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '모멘티 탐색',
                                  style: TextStyle(
                                    color: Colors.white,
                                                fontSize: 16 * scale,
                                    fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(width: 4 * scale),
                                        Icon(Icons.search, color: Colors.white, size: 24 * scale),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              
              // 필터 칩~카드 리스트 영역을 Expanded로 감싸서 카드가 바닥에 닿게
              Expanded(
                child: Column(
                  children: [
                    // Black section with filters
                    Container(
                      width: double.infinity,
                      height: 45 * scale,
                      color: Colors.black,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(horizontal: 5 * scale),
                        child: Row(
                          children: filterOptions.map((filter) => 
                            FilterChip(
                              label: filter,
                              selected: selectedFilter == filter,
                              onTap: () => setState(() => selectedFilter = filter),
                              scale: scale,
                            )
                          ).toList(),
                        ),
                      ),
                    ),
                    // Cards section
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: EdgeInsets.fromLTRB(16 * scale, 21 * scale, 16 * scale, 8 * scale),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              children: [
                                Text(
                                  '내가 깨운 사물들',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.bold,
                                    height: 1.4,
                                  ),
                                ),
                                SizedBox(width: 12 * scale),
                                Container(
                                  width: 20 * scale,
                                  height: 20 * scale,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(10 * scale),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '99',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16 * scale),
                            // Horizontal scrollable cards
                            SizedBox(
                              height: 240 * scale,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: objectData.length,
                                separatorBuilder: (context, index) => SizedBox(width: 12 * scale),
                                itemBuilder: (context, index) => ObjectCard(
                                  data: objectData[index],
                                  scale: scale,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double scale;

  const FilterChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32 * scale,
        margin: EdgeInsets.symmetric(horizontal: 2 * scale),
        padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 6 * scale),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(40 * scale),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check, size: 12 * scale, color: Colors.black),
              SizedBox(width: 8 * scale),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : Colors.white,
                fontSize: 14 * scale,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ObjectCard extends StatelessWidget {
  final ObjectData data;
  final double scale;

  const ObjectCard({Key? key, required this.data, this.scale = 1.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148 * scale,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom shaped image container
          Container(
            width: 148 * scale,
            height: 148 * scale,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
            ),
            child: ClipPath(
              clipper: CustomShapeClipper(),
              child: data.imageUrl != null
                  ? Image.network(
                      data.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Color(0xFFF7F7F7),
                      ),
                    )
                  : Container(color: Color(0xFFF7F7F7)),
            ),
          ),
          
          SizedBox(height: 12 * scale),
          
          // Location
          Text(
            data.location,
            style: TextStyle(
              color: Color(0xFF999999),
              fontSize: 12 * scale,
              height: 1.4,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          
          SizedBox(height: 2 * scale),
          
          // Title and NEW badge
          Row(
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14 * scale,
                    height: 1.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.isNew) ...[
                SizedBox(width: 8 * scale),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 3 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFEB3B),
                    borderRadius: BorderRadius.circular(2 * scale),
                    border: Border.all(color: Color(0xFFE0E0E0), width: 0.4 * scale),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 6 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: 2 * scale),
          
          // Duration
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: data.duration.split(' ')[0] + ' ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: data.duration.split(' ')[1],
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12 * scale,
                  ),
                ),
              ],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    
    // Create a rounded diamond-like shape
    double width = size.width;
    double height = size.height;
    
    path.moveTo(width * 0.5, 0);
    path.quadraticBezierTo(width * 0.85, height * 0.15, width, height * 0.3);
    path.quadraticBezierTo(width * 0.85, height * 0.5, width, height * 0.7);
    path.quadraticBezierTo(width * 0.85, height * 0.85, width * 0.5, height);
    path.quadraticBezierTo(width * 0.15, height * 0.85, 0, height * 0.7);
    path.quadraticBezierTo(width * 0.15, height * 0.5, 0, height * 0.3);
    path.quadraticBezierTo(width * 0.15, height * 0.15, width * 0.5, 0);
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ObjectData {
  final String title;
  final String location;
  final String duration;
  final String? imageUrl;
  final bool isNew;

  ObjectData({
    required this.title,
    required this.location,
    required this.duration,
    this.imageUrl,
    this.isNew = false,
  });
}