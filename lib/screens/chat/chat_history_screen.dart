import 'package:flutter/material.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  String _selectedFilter = 'all'; // 'all', 'moments', 'friends'

  // 사물 기반 채팅 데이터
  final List<ChatHistoryItem> _chatHistory = [
    ChatHistoryItem(
      id: '1',
      username: 'starryskies23',
      handle: '@starry',
      avatar: 'assets/profile.png',
      lastMessage: '내 방이 그 모이야',
      timestamp: '1d',
      isOnline: true,
      category: 'moments',
      objectName: '털찐 말랑이',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      unreadCount: 1,
      hasUnread: true,
      isNewChat: true, // 새로운 채팅방
    ),
    ChatHistoryItem(
      id: '2',
      username: 'nebulanomad',
      handle: '@nebula',
      avatar: 'assets/profile.png',
      lastMessage: '명동쪽도 쉬고싶다며..파업한다며',
      timestamp: '1d',
      isOnline: true,
      category: 'moments',
      objectName: '도시락통',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasLocationPhoto: true,
      locationPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 장소 이미지 URL
      hasReaction: true,
      isNewChat: true, // 새로운 채팅방
    ),
    ChatHistoryItem(
      id: '3',
      username: 'emberecho',
      handle: '@ember',
      avatar: 'assets/profile.png',
      lastMessage: '내 매직시에 좋아요를 눌렀어요\n생추욱~~~!!! 🎉🎊',
      timestamp: '2d',
      isOnline: false,
      category: 'moments',
      objectName: '커피머그컵',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasLocationPhoto: true,
      locationPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 장소 이미지 URL
    ),
    ChatHistoryItem(
      id: '4',
      username: 'lunavoyager',
      handle: '@luna',
      avatar: 'assets/profile.png',
      lastMessage: '내 글을 저장했어요.',
      timestamp: '3d',
      isOnline: false,
      category: 'moments',
      objectName: '다이어리',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasLocationPhoto: true,
      locationPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 장소 이미지 URL
    ),
    ChatHistoryItem(
      id: '5',
      username: 'shadowlynx',
      handle: '@shadow',
      avatar: 'assets/profile.png',
      lastMessage: '내 매직시에 댓글을 남왔어요\n8월에 가능한 좋은 생각이야!\n너는 어디로 여행가고 싶어?',
      timestamp: '4d',
      isOnline: false,
      category: 'moments',
      objectName: '여행가방',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasLocationPhoto: true,
      locationPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 장소 이미지 URL
    ),
    ChatHistoryItem(
      id: '6',
      username: 'nebulanomad',
      handle: '@nebula2',
      avatar: 'assets/profile.png',
      lastMessage: '사진을 공유했어요.',
      timestamp: '5d',
      isOnline: false,
      category: 'friends',
      objectName: '친구 핸드폰',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasLocationPhoto: true,
      locationPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 장소 이미지 URL
      isVisitor: true,
      hasReaction: true,
      isNewChat: true, // 새로운 채팅방 (친구 오브젝트)
    ),
    ChatHistoryItem(
      id: '7',
      username: 'lunavoyager',
      handle: '@luna2',
      avatar: 'assets/profile.png',
      lastMessage: '내 매직시에 좋아요를 눌렀어요\n정말 잘했다!!!',
      timestamp: '5d',
      isOnline: false,
      category: 'friends',
      objectName: '친구 노트북',
      objectPhoto: 'assets/profile.png', // 실제로는 서버에서 받아온 사물 프로필 이미지 URL
      hasUnread: true,
      unreadCount: 3,
      isVisitor: true,
      hasReaction: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  List<ChatHistoryItem> get _filteredChatHistory {
    switch (_selectedFilter) {
      case 'moments':
        return _chatHistory
            .where((chat) => chat.category == 'moments')
            .toList();
      case 'friends':
        return _chatHistory
            .where((chat) => chat.category == 'friends')
            .toList();
      case 'all':
      default:
        return _chatHistory;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // 흰색 배경
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E9), // 아이보리색 앱바
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '챗 히스토리',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [_buildFilterButtons(), Expanded(child: _buildChatList())],
      ),
    );
  }

  Widget _buildChatList() {
    final filteredChats = _filteredChatHistory;

    if (filteredChats.isEmpty) {
      return const Center(
        child: Text(
          '채팅 내역이 없습니다',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
        return _buildChatItem(chat);
      },
    );
  }

  Widget _buildChatItem(ChatHistoryItem chat) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openChat(chat),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 사물 프로필 사진 + 읽지 않은 메시지 마커
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(
                        chat.objectPhoto ?? chat.avatar,
                      ),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    // 새로운 채팅방 빨간 점 (절대 위치)
                    if (chat.isNewChat)
                      Positioned(
                        left: -12,
                        top: 20,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (chat.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    // 읽지 않은 메시지 마커
                    if (chat.hasUnread && chat.unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // 채팅 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // 사물 애칭
                              Text(
                                chat.objectName ?? chat.username,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              if (chat.isVisitor) ...[
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    '방문',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // 마지막 메시지 수신일
                          Text(
                            chat.timestamp,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      // 사용자명 + 반응 알림
                      Row(
                        children: [
                          Text(
                            '@${chat.username}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (chat.hasReaction) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.pink.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '❤️ 반응',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.pink.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      // 마지막 메시지
                      Text(
                        chat.lastMessage,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // 장소 사진 썸네일 및 읽지 않은 메시지 표시
                Column(
                  children: [
                    if (chat.hasLocationPhoto)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            chat.locationPhoto,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    if (chat.hasUnread && chat.unreadCount == 0)
                      Container(
                        margin: const EdgeInsets.only(left: 8, top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '더보기',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      color: const Color(0xFFFDF7E9), // 필터링란만 아이보리색
      padding: const EdgeInsets.all(16), // 패딩을 다시 16으로 복원
      child: Row(
        children: [
          _buildFilterButton('전체', 'all'),
          const SizedBox(width: 12),
          _buildFilterButton('내 모멘티', 'moments'),
          const SizedBox(width: 12),
          _buildFilterButton('@유저명', 'friends'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String title, String filterValue) {
    final isSelected = _selectedFilter == filterValue;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterValue;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  void _openChat(ChatHistoryItem chat) {
    // 리스트 클릭 시 버튼 활성화 - 채팅 화면으로 이동
    print('Opening chat with object: ${chat.objectName} by ${chat.username}');
    // TODO: 실제 채팅 화면으로 네비게이션
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('${chat.objectName}과의 채팅'),
            content: Text(
              '${chat.username}님이 만든 ${chat.objectName}과 채팅을 시작합니다.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('확인'),
              ),
            ],
          ),
    );
  }
}

class ChatHistoryItem {
  final String id;
  final String username;
  final String handle;
  final String avatar;
  final String lastMessage;
  final String timestamp;
  final bool isOnline;
  final String category;
  final bool hasLocationPhoto;
  final String locationPhoto;
  final bool hasUnread;
  final String? objectName; // 사물 애칭
  final String? objectPhoto; // 사물 프로필 사진
  final bool isVisitor;
  final int unreadCount; // 읽지 않은 메시지 마커
  final bool hasReaction; // 메시지에 대한 반응 알림
  final bool isNewChat; // 새로운 채팅방

  ChatHistoryItem({
    required this.id,
    required this.username,
    required this.handle,
    required this.avatar,
    required this.lastMessage,
    required this.timestamp,
    this.isOnline = false,
    required this.category,
    this.hasLocationPhoto = false,
    this.locationPhoto = '',
    this.hasUnread = false,
    this.objectName,
    this.objectPhoto,
    this.isVisitor = false,
    this.unreadCount = 0,
    this.hasReaction = false,
    this.isNewChat = false,
  });
}
