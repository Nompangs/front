import 'package:flutter/material.dart';

// 모멘티 데이터 모델 - 기존 ObjectData를 확장
class MomentiData {
  final String name; // 사물애칭
  final String userId; // 사용자 ID
  final String location; // 위치
  final double distance; // 거리 (km)
  final int subscribers; // 구독자 수
  final String imageUrl; // 이미지 URL
  final bool isPromoted; // 프로모션 여부
  final Color? backgroundColor; // 배경색

  MomentiData({
    required this.name,
    required this.userId,
    required this.location,
    required this.distance,
    required this.subscribers,
    required this.imageUrl,
    this.isPromoted = false,
    this.backgroundColor,
  });
}

class FindMomentiScreen extends StatefulWidget {
  const FindMomentiScreen({Key? key}) : super(key: key);

  @override
  State<FindMomentiScreen> createState() => _FindMomentiScreenState();
}

class _FindMomentiScreenState extends State<FindMomentiScreen> {
  String _selectedHashtag = '';
  List<MomentiData> _filteredMomentiList = [];

  // 필터링 상태
  bool _sortByDistance = true; // 거리순 정렬
  bool _filterByOwner = false; // 소유자 필터 (특정 소유자만 보기)
  List<MomentiData> _displayedMomentiList = [];

  // 검색 관련 상태
  final TextEditingController _searchController = TextEditingController();
  String _currentLocation = '정자동';
  bool _isSearching = false;

  // 확장된 더미데이터
  final List<MomentiData> momentiList = [
    MomentiData(
      name: '분당 영쿠션',
      userId: '@nompangs',
      location: '분당구 정자동',
      distance: 1.2,
      subscribers: 1300,
      imageUrl: 'assets/ui_assets/cushion.png',
      backgroundColor: Color(0xFFFFA726),
    ),
    MomentiData(
      name: '디자인 체어',
      userId: '@designer_kim',
      location: '강남구 역삼동',
      distance: 2.4,
      subscribers: 850,
      imageUrl: 'assets/testImg_1.png',
      backgroundColor: Color(0xFF81C784),
    ),
    MomentiData(
      name: '제임쓰 카페인쓰',
      userId: '@coffee_lover',
      location: '마포구 홍대입구',
      distance: 0.8,
      subscribers: 2200,
      imageUrl: 'assets/testImg_2.png',
      backgroundColor: Color(0xFF8BC34A),
      isPromoted: true,
    ),
    MomentiData(
      name: '빈백 소파',
      userId: '@cozy_home',
      location: '서초구 서초동',
      distance: 3.1,
      subscribers: 1200,
      imageUrl: 'assets/testImg_3.png',
      backgroundColor: Color(0xFFFF7043),
    ),
    MomentiData(
      name: '테스트 소파',
      userId: '@furniture_fan',
      location: '용산구 이태원동',
      distance: 1.9,
      subscribers: 1100,
      imageUrl: 'assets/testImg_4.png',
      backgroundColor: Color(0xFF5C6BC0),
    ),
    MomentiData(
      name: '빈티지 램프',
      userId: '@vintage_lover',
      location: '종로구 인사동',
      distance: 4.2,
      subscribers: 320,
      imageUrl: 'assets/testImg_5.png',
      backgroundColor: Color(0xFFAB47BC),
    ),
    MomentiData(
      name: '마이펫 인형',
      userId: '@pet_collector',
      location: '성동구 성수동',
      distance: 2.8,
      subscribers: 1800,
      imageUrl: 'assets/testImg_1.png',
      backgroundColor: Color(0xFFEF5350),
      isPromoted: true,
    ),
    MomentiData(
      name: '창원김씨의 머그컵',
      userId: '@changwon_kim',
      location: '송파구 잠실동',
      distance: 5.1,
      subscribers: 420,
      imageUrl: 'assets/testImg_2.png',
      backgroundColor: Color(0xFF66BB6A),
    ),
    MomentiData(
      name: '춘자의 화분',
      userId: '@spring_chun',
      location: '마포구 합정동',
      distance: 3.7,
      subscribers: 680,
      imageUrl: 'assets/testImg_3.png',
      backgroundColor: Color(0xFF4CAF50),
    ),
    MomentiData(
      name: '김봉봉 인형',
      userId: '@bongbong_lover',
      location: '강서구 화곡동',
      distance: 6.2,
      subscribers: 290,
      imageUrl: 'assets/testImg_4.png',
      backgroundColor: Color(0xFFFF9800),
    ),
    MomentiData(
      name: '빈티지 램프',
      userId: '@vintage_style',
      location: '종로구 인사동',
      distance: 4.8,
      subscribers: 750,
      imageUrl: 'assets/testImg_5.png',
      backgroundColor: Color(0xFF9C27B0),
    ),
    MomentiData(
      name: '테스트 소파',
      userId: '@sofa_tester',
      location: '용산구 이태원동',
      distance: 3.3,
      subscribers: 920,
      imageUrl: 'assets/testImg_1.png',
      backgroundColor: Color(0xFF3F51B5),
    ),
    MomentiData(
      name: '제임쓰 카페인쓰',
      userId: '@james_caffeine',
      location: '마포구 홍대입구',
      distance: 2.1,
      subscribers: 1650,
      imageUrl: 'assets/testImg_2.png',
      backgroundColor: Color(0xFF795548),
      isPromoted: true,
    ),
    MomentiData(
      name: '모던 책상',
      userId: '@modern_desk',
      location: '서초구 강남역',
      distance: 1.8,
      subscribers: 480,
      imageUrl: 'assets/testImg_3.png',
      backgroundColor: Color(0xFF607D8B),
    ),
    MomentiData(
      name: '아늑한 쿠션',
      userId: '@cozy_home',
      location: '강남구 신사동',
      distance: 2.7,
      subscribers: 1200,
      imageUrl: 'assets/testImg_4.png',
      backgroundColor: Color(0xFFE91E63),
    ),
    MomentiData(
      name: '원목 의자',
      userId: '@wood_furniture',
      location: '성북구 성신여대입구',
      distance: 5.4,
      subscribers: 380,
      imageUrl: 'assets/testImg_5.png',
      backgroundColor: Color(0xFF8BC34A),
    ),
    MomentiData(
      name: '스마트 조명',
      userId: '@smart_light',
      location: '노원구 상계동',
      distance: 7.1,
      subscribers: 620,
      imageUrl: 'assets/testImg_1.png',
      backgroundColor: Color(0xFFFF5722),
    ),
    // @cozy_home 사용자의 추가 모멘티들 (다른 장소)
    MomentiData(
      name: '북유럽 테이블',
      userId: '@cozy_home',
      location: '마포구 상수동',
      distance: 4.5,
      subscribers: 1200,
      imageUrl: 'assets/testImg_2.png',
      backgroundColor: Color(0xFF4CAF50),
    ),
    MomentiData(
      name: '감성 조명',
      userId: '@cozy_home',
      location: '용산구 한남동',
      distance: 2.9,
      subscribers: 1200,
      imageUrl: 'assets/testImg_5.png',
      backgroundColor: Color(0xFF9C27B0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateDisplayedList();
    _searchController.text = _currentLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 필터링 및 정렬 로직
  void _updateDisplayedList() {
    List<MomentiData> tempList = List.from(momentiList);

    // 소유자 필터링 (인기 소유자만 보기)
    if (_filterByOwner) {
      tempList =
          tempList
              .where(
                (momenti) =>
                    momenti.subscribers >= 1000, // 1000명 이상 구독자를 가진 소유자만
              )
              .toList();
    }

    // 거리순 정렬
    if (_sortByDistance) {
      tempList.sort((a, b) => a.distance.compareTo(b.distance));
    } else {
      // 구독자순 정렬 (거리순이 아닐 때)
      tempList.sort((a, b) => b.subscribers.compareTo(a.subscribers));
    }

    setState(() {
      _displayedMomentiList = tempList;
    });
  }

  // 검색 기능
  void _performSearch(String query) {
    if (query.isEmpty) {
      _updateDisplayedList();
      return;
    }

    List<MomentiData> searchResults = [];

    // 지역 검색인지 확인 (구, 동이 포함된 경우)
    if (query.contains('구') || query.contains('동')) {
      // 지역 검색
      searchResults =
          momentiList
              .where((momenti) => momenti.location.contains(query))
              .toList();

      setState(() {
        _currentLocation = query;
        _displayedMomentiList = searchResults;
      });

      // 지역 검색 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$query 지역으로 이동했습니다'),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      // 사용자 ID로 검색하는 경우 (@ 포함)
      if (query.startsWith('@')) {
        List<MomentiData> userMomenti =
            momentiList
                .where(
                  (momenti) =>
                      momenti.userId.toLowerCase() == query.toLowerCase(),
                )
                .toList();

        if (userMomenti.isNotEmpty) {
          setState(() {
            _displayedMomentiList = userMomenti;
          });

          // 해당 사용자의 모든 모멘티를 모달로 표시
          _showUserMomenti(query);
          return;
        }
      }

      // 모멘티 이름/사용자 ID 부분 검색
      searchResults =
          momentiList
              .where(
                (momenti) =>
                    momenti.name.toLowerCase().contains(query.toLowerCase()) ||
                    momenti.userId.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();

      setState(() {
        _displayedMomentiList = searchResults;
      });

      if (searchResults.isNotEmpty) {
        // 사용자 ID가 포함된 검색인지 확인
        bool isUserSearch = searchResults.any(
          (momenti) =>
              momenti.userId.toLowerCase().contains(query.toLowerCase()),
        );

        if (isUserSearch) {
          // 사용자 검색이면 해당 사용자의 모든 모멘티 표시
          String userId = searchResults.first.userId;
          _showUserMomenti(userId);
        } else {
          // 모멘티 이름 검색이면 해당 해시태그 모달 표시
          String hashtag = '#${searchResults.first.name.replaceAll(' ', '')}';
          _showMomentiForHashtag(hashtag);
        }
      }
    }
  }

  // 같은 사용자의 모멘티 모두 보기
  void _showUserMomenti(String userId) {
    List<MomentiData> userMomenti =
        momentiList.where((momenti) => momenti.userId == userId).toList();

    if (userMomenti.isNotEmpty) {
      setState(() {
        _filteredMomentiList = userMomenti;
      });

      // 사용자 모멘티 모달 표시
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: true, // 밖을 클릭하면 모달이 닫힘
        enableDrag: true, // 드래그로 닫기 가능
        builder: (context) => _buildUserMomentiBottomSheet(userId, userMomenti),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 상단 아이보리색 배경 (앱바 + 검색 + 필터 영역)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 180, // 필터 버튼까지 포함하는 높이
              child: Container(color: const Color(0xFFFDF7E9)),
            ),
            // 지도 배경 (회색+흰색 블록) - 상단 UI 아래부터 화면 끝까지
            Positioned(
              top: 180,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: _MapGridPainter(),
                  size: Size.infinite,
                ),
              ),
            ),
            // 상단 앱바
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 56,
                color: const Color(0xFFFDF7E9), // 아이보리색 배경
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
                  borderRadius: BorderRadius.circular(40),
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
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '지역, 모멘티 이름, 사용자 검색...',
                          hintStyle: TextStyle(color: Colors.black54),
                        ),
                        style: TextStyle(fontSize: 16, color: Colors.black),
                        onSubmitted: (value) => _performSearch(value),
                        onChanged: (value) {
                          if (value.isEmpty) {
                            _updateDisplayedList();
                          }
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _performSearch(_searchController.text),
                      child: Icon(Icons.search, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
            // 정렬/필터/결과수
            Positioned(
              top: 140, // 검색창과 간격 조정 (120 -> 140)
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // 거리순 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortByDistance = true;
                      });
                      _showSortedResults(); // 거리순 정렬된 결과를 모달로 표시
                    },
                    child: _FilterChip(label: '거리순', selected: _sortByDistance),
                  ),
                  SizedBox(width: 8),
                  // 인기순 버튼
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortByDistance = false;
                      });
                      _showSortedResults(); // 인기순 정렬된 결과를 모달로 표시
                    },
                    child: _FilterChip(
                      label: '인기순',
                      selected: !_sortByDistance,
                    ),
                  ),
                  Spacer(),
                  Text(
                    '${momentiList.length} results',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ],
              ),
            ),
            // 해시태그 마커들
            _buildHashtagMarkers(width, height),
          ],
        ),
      ),
    );
  }

  Widget _buildHashtagMarkers(double width, double height) {
    return Stack(
      children: [
        // 화면 전체에 자연스럽게 분산 배치된 해시태그들
        _HashtagMarker(
          label: '🔥#분당영쿠션',
          left: width * 0.15,
          top: height * 0.25,
          isMain: _selectedHashtag == '#분당영쿠션',
          onTap: () => _showMomentiForHashtag('#분당영쿠션'),
          isPopular: true, // 1300 구독자 - 중인기
        ),
        _HashtagMarker(
          label: '#디자인체어',
          left: width * 0.7,
          top: height * 0.22,
          isMain: _selectedHashtag == '#디자인체어',
          onTap: () => _showMomentiForHashtag('#디자인체어'),
          // 850 구독자 - 일반
        ),
        _HashtagMarker(
          label: '✨🔥#마이펫',
          left: width * 0.4,
          top: height * 0.28,
          isMain: _selectedHashtag == '#마이펫',
          onTap: () => _showMomentiForHashtag('#마이펫'),
          isPromoted: true, // 프로모션
          isPopular: true, // 1800 구독자 - 고인기
        ),
        _HashtagMarker(
          label: '#빈백소파',
          left: width * 0.85,
          top: height * 0.35,
          isMain: _selectedHashtag == '#빈백소파',
          onTap: () => _showMomentiForHashtag('#빈백소파'),
          // 560 구독자 - 일반
        ),
        _HashtagMarker(
          label: '✨🔥#제임쓰카페인쓰',
          left: width * 0.08,
          top: height * 0.38,
          isMain: _selectedHashtag == '#제임쓰카페인쓰',
          onTap: () => _showMomentiForHashtag('#제임쓰카페인쓰'),
          isPromoted: true, // 프로모션 (2200, 1650 구독자)
          isPopular: true, // 고인기
        ),
        _HashtagMarker(
          label: '#김봉봉',
          left: width * 0.6,
          top: height * 0.42,
          isMain: _selectedHashtag == '#김봉봉',
          onTap: () => _showMomentiForHashtag('#김봉봉'),
          // 290 구독자 - 일반
        ),
        _HashtagMarker(
          label: '#창원김씨머그컵',
          left: width * 0.25,
          top: height * 0.48,
          isMain: _selectedHashtag == '#창원김씨머그컵',
          onTap: () => _showMomentiForHashtag('#창원김씨머그컵'),
          // 420 구독자 - 일반
        ),
        _HashtagMarker(
          label: '#춘자화분',
          left: width * 0.78,
          top: height * 0.52,
          isMain: _selectedHashtag == '#춘자화분',
          onTap: () => _showMomentiForHashtag('#춘자화분'),
          // 680 구독자 - 일반
        ),
        _HashtagMarker(
          label: '#빈티지램프',
          left: width * 0.12,
          top: height * 0.58,
          isMain: _selectedHashtag == '#빈티지램프',
          onTap: () => _showMomentiForHashtag('#빈티지램프'),
          // 320, 750 구독자 - 일반
        ),
        _HashtagMarker(
          label: '🔥#테스트소파',
          left: width * 0.55,
          top: height * 0.62,
          isMain: _selectedHashtag == '#테스트소파',
          onTap: () => _showMomentiForHashtag('#테스트소파'),
          isPopular: true, // 1100, 920 구독자 - 중인기
        ),
        _HashtagMarker(
          label: '#모던책상',
          left: width * 0.35,
          top: height * 0.68,
          isMain: _selectedHashtag == '#모던책상',
          onTap: () => _showMomentiForHashtag('#모던책상'),
          // 480 구독자 - 일반
        ),
        _HashtagMarker(
          label: '🔥#아늑한쿠션',
          left: width * 0.82,
          top: height * 0.72,
          isMain: _selectedHashtag == '#아늑한쿠션',
          onTap: () => _showMomentiForHashtag('#아늑한쿠션'),
          isPopular: true, // 1200 구독자 - 중인기
        ),
        _HashtagMarker(
          label: '#원목의자',
          left: width * 0.18,
          top: height * 0.75,
          isMain: _selectedHashtag == '#원목의자',
          onTap: () => _showMomentiForHashtag('#원목의자'),
          // 380 구독자 - 일반
        ),
        _HashtagMarker(
          label: '#스마트조명',
          left: width * 0.65,
          top: height * 0.78,
          isMain: _selectedHashtag == '#스마트조명',
          onTap: () => _showMomentiForHashtag('#스마트조명'),
          // 620 구독자 - 일반
        ),
        // 새로 추가된 @cozy_home 모멘티들
        _HashtagMarker(
          label: '🔥#북유럽테이블',
          left: width * 0.45,
          top: height * 0.82,
          isMain: _selectedHashtag == '#북유럽테이블',
          onTap: () => _showMomentiForHashtag('#북유럽테이블'),
          isPopular: true, // 1200 구독자 - 중인기
        ),
        _HashtagMarker(
          label: '🔥#감성조명',
          left: width * 0.25,
          top: height * 0.85,
          isMain: _selectedHashtag == '#감성조명',
          onTap: () => _showMomentiForHashtag('#감성조명'),
          isPopular: true, // 1200 구독자 - 중인기
        ),
      ],
    );
  }

  // 정렬된 결과를 모달로 표시
  void _showSortedResults() {
    // 전체 모멘티 리스트를 정렬
    _filteredMomentiList = List.from(momentiList);

    if (_sortByDistance) {
      // 거리순 정렬 (가까운 순)
      _filteredMomentiList.sort((a, b) => a.distance.compareTo(b.distance));
    } else {
      // 인기순 정렬 (구독자 많은 순)
      _filteredMomentiList.sort(
        (a, b) => b.subscribers.compareTo(a.subscribers),
      );
    }

    // 모달 바텀시트로 표시
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // 밖을 클릭하면 모달이 닫힘
      enableDrag: true, // 드래그로 닫기 가능
      builder: (context) => _buildSortedMomentiBottomSheet(),
    );
  }

  void _showMomentiForHashtag(String hashtag) {
    setState(() {
      _selectedHashtag = hashtag;
    });

    // 검색 상태와 관계없이 전체 모멘티 리스트에서 해시태그에 따라 모멘티 필터링 (사물 이름 기준)
    List<MomentiData> sourceList = momentiList;

    switch (hashtag) {
      case '#분당영쿠션':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('분당 영쿠션'))
                .toList();
        break;
      case '#디자인체어':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('디자인 체어'))
                .toList();
        break;
      case '#빈백소파':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('빈백 소파'))
                .toList();
        break;
      case '#마이펫':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('마이펫'))
                .toList();
        break;
      case '#김봉봉':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('김봉봉'))
                .toList();
        break;
      case '#창원김씨머그컵':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('창원김씨'))
                .toList();
        break;
      case '#춘자화분':
        _filteredMomentiList =
            sourceList.where((momenti) => momenti.name.contains('춘자')).toList();
        break;
      case '#빈티지램프':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('빈티지 램프'))
                .toList();
        break;
      case '#테스트소파':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('테스트 소파'))
                .toList();
        break;
      case '#제임쓰카페인쓰':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('제임쓰 카페인쓰'))
                .toList();
        break;
      case '#모던책상':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('모던 책상'))
                .toList();
        break;
      case '#아늑한쿠션':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('아늑한 쿠션'))
                .toList();
        break;
      case '#원목의자':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('원목 의자'))
                .toList();
        break;
      case '#스마트조명':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('스마트 조명'))
                .toList();
        break;
      case '#북유럽테이블':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('북유럽 테이블'))
                .toList();
        break;
      case '#감성조명':
        _filteredMomentiList =
            sourceList
                .where((momenti) => momenti.name.contains('감성 조명'))
                .toList();
        break;
      default:
        _filteredMomentiList = sourceList;
    }

    // 필터링된 결과가 없으면 현재 표시된 리스트 사용
    if (_filteredMomentiList.isEmpty) {
      _filteredMomentiList = sourceList;
    }

    // 모달 바텀시트로 표시 (드래그 가능)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // 밖을 클릭하면 모달이 닫힘
      enableDrag: true, // 드래그로 닫기 가능
      builder: (context) => _buildDraggableMomentiBottomSheet(),
    );
  }

  Widget _buildDraggableMomentiBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // 초기 50% 높이
      minChildSize: 0.3, // 최소 30% 높이
      maxChildSize: 0.9, // 최대 90% 높이
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 핸들바 (드래그 가능)
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // 헤더
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _selectedHashtag ?? '해시태그 모멘티',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${_filteredMomentiList.length}개 모멘티',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // 모멘티 리스트 (스크롤 가능)
              Expanded(
                child: ListView.builder(
                  controller:
                      scrollController, // DraggableScrollableSheet의 컨트롤러 사용
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredMomentiList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _MomentiListCard(
                          data: _filteredMomentiList[index],
                          onNameTap:
                              () => _showUserInfoPopup(
                                _filteredMomentiList[index],
                              ),
                          onUserTap:
                              () => _showUserMomenti(
                                _filteredMomentiList[index].userId,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 정렬된 모멘티 리스트를 보여주는 바텀시트 (드래그 가능, 50%~90% 높이)
  Widget _buildSortedMomentiBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.5, // 초기 50% 높이
      minChildSize: 0.5, // 최소 50% 높이
      maxChildSize: 0.9, // 최대 90% 높이 (필터 아래까지)
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 핸들바 (탭하면 90%로 확장) - 간단한 방법으로 수정
              Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              // 헤더
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _sortByDistance ? '거리순 정렬' : '인기순 정렬',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${_filteredMomentiList.length}개 모멘티',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              // 모멘티 리스트 (스크롤 가능)
              Expanded(
                child: ListView.builder(
                  controller:
                      scrollController, // DraggableScrollableSheet의 컨트롤러 사용
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredMomentiList.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _MomentiListCard(
                          data: _filteredMomentiList[index],
                          onNameTap:
                              () => _showUserInfoPopup(
                                _filteredMomentiList[index],
                              ),
                          onUserTap:
                              () => _showUserMomenti(
                                _filteredMomentiList[index].userId,
                              ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 사용자의 모든 모멘티를 보여주는 바텀시트
  Widget _buildUserMomentiBottomSheet(
    String userId,
    List<MomentiData> userMomenti,
  ) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들바
          Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      userMomenti.first.backgroundColor ?? Colors.grey,
                  child: Text(
                    userId.substring(1, 2).toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$userId의 모멘티',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${userMomenti.length}개의 모멘티',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          // 모멘티 리스트 (스크롤 가능)
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: userMomenti.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _MomentiListCard(
                      data: userMomenti[index],
                      onNameTap: () => _showUserInfoPopup(userMomenti[index]),
                      onUserTap:
                          () => _showUserMomenti(userMomenti[index].userId),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showUserInfoPopup(MomentiData momenti) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // 밖을 클릭하면 모달이 닫힘
      enableDrag: true, // 드래그로 닫기 가능
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(top: 12, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: momenti.backgroundColor ?? Colors.grey,
                    child: Text(
                      momenti.userId.substring(1, 2).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    momenti.userId,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${momenti.location}에서 활동 중',
                    style: TextStyle(color: Colors.black54),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            '${(momenti.subscribers / 1000).toStringAsFixed(1)}K',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('구독자', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                      Container(width: 1, height: 30, color: Colors.black12),
                      Column(
                        children: [
                          Text(
                            '${momenti.distance}km',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('거리', style: TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('팔로우하기', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 16), // 하단 여백 추가
                ],
              ),
            ),
          ),
    );
  }

  void _showHashtagPopup(String hashtag, String description) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true, // 밖을 클릭하면 모달이 닫힘
      enableDrag: true, // 드래그로 닫기 가능
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 핸들바
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: 12, bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 해시태그 아이콘
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(0xFFFDF7E9),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tag, size: 30, color: Colors.black),
              ),
              SizedBox(height: 16),
              // 해시태그 제목
              Text(
                hashtag,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),
              // 설명
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ),
              SizedBox(height: 32),
              // 액션 버튼들
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.black12),
                        ),
                        child: Text(
                          '닫기',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$hashtag 모멘티들을 검색합니다'),
                              backgroundColor: Colors.black,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          '검색하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        );
      },
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
  final bool isPromoted;
  final bool isPopular;
  final VoidCallback? onTap;

  const _HashtagMarker({
    required this.label,
    required this.left,
    required this.top,
    this.isMain = false,
    this.isPromoted = false,
    this.isPopular = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 배경색/그라데이션 결정
    Color? backgroundColor;
    Gradient? backgroundGradient;

    if (isMain) {
      backgroundColor = Colors.black;
    } else if (isPromoted) {
      // 프로모션: 골드 그라데이션
      backgroundGradient = LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // 인기든 일반이든 흰색 배경
      backgroundColor = Colors.white;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPromoted ? Colors.transparent : Colors.black12,
            ),
            boxShadow:
                onTap != null
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          isPromoted ? 0.15 : 0.1,
                        ),
                        blurRadius: isPromoted ? 6 : 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isMain || isPromoted ? Colors.white : Colors.black,
              fontWeight:
                  isPromoted || isPopular ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
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

class _MomentiListCard extends StatelessWidget {
  final MomentiData data;
  final VoidCallback? onNameTap;
  final VoidCallback? onUserTap;

  const _MomentiListCard({required this.data, this.onNameTap, this.onUserTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 프로모션 배너
          if (data.isPromoted)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFFFEB3B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  '🎉 프로모션 모멘티',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          // 이미지 섹션 - 꽉 채우기
          Container(
            height: 160, // 높이를 줄여서 오버플로우 방지
            width: double.infinity,
            decoration: BoxDecoration(
              color: data.backgroundColor ?? Color(0xFFFFA726),
              borderRadius:
                  data.isPromoted
                      ? BorderRadius.zero
                      : BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: ClipRRect(
              borderRadius:
                  data.isPromoted
                      ? BorderRadius.zero
                      : BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                data.imageUrl,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover, // 이미지 꽉 채우기
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(color: Colors.black12),
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.black38,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 정보 섹션
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onNameTap,
                  child: Text(
                    data.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.black45),
                    SizedBox(width: 4),
                    GestureDetector(
                      onTap: onUserTap,
                      child: Text(
                        data.userId,
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: Colors.black45),
                    SizedBox(width: 4),
                    Text(
                      '${data.distance} km',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${(data.subscribers / 1000).toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 2),
                    Text('천 구독자', style: TextStyle(color: Colors.black54)),
                    Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // 상세 페이지로 이동
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${data.name} 상세 페이지로 이동')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 0,
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '더보기',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
