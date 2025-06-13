import 'package:flutter/material.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: Colors.black,
          border: Border.all(color: Colors.black, width: 1),
        ),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Status Bar
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF7E9),
                  border: Border(
                    top: BorderSide(color: Colors.black, width: 1),
                    right: BorderSide(color: Colors.black, width: 1),
                    left: BorderSide(color: Colors.black, width: 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '9:41',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'SF Pro Text',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 60, top: 1, bottom: 1),
                      child: Row(
                        children: [
                          Container(
                            width: 17,
                            height: 10,
                            child: Image.network(
                              'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/def7a97d2043c8c75f03a416e5b960bf785ff542?placeholderIfAbsent=true',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            width: 15,
                            height: 11,
                            child: Image.network(
                              'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/cec070c865b767daa2390c27d4f615cecdc1646a?placeholderIfAbsent=true',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Header with navigation and profile
              Container(
                color: const Color(0xFFFDF7E9),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                        child: Container(
                          width: 156,
                          height: 24,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Image.network(
                        'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/f11e6d3bce99d478dd53ef9cb04a99d5cf92d61e?placeholderIfAbsent=true',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Main image section
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.width / 1.078,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/ee2fa748f3502423998f235154bcc07bb8129f70?placeholderIfAbsent=true',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 19,
                      left: 0,
                      right: 0,
                      child: Image.network(
                        'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/b5ab5995be0028b8a918e015af12078a57af4a31?placeholderIfAbsent=true',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Filter chips section
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(5),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Active filter chip (전체)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          color: Colors.white,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.network(
                                'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/05b4cc250fc698fb424076bde970a280d6a1922d?placeholderIfAbsent=true',
                                width: 18,
                                height: 18,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '전체',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      
                      // Inactive filter chips
                      _buildFilterChip('내 방'),
                      const SizedBox(width: 5),
                      _buildFilterChip('우리집 안방'),
                      const SizedBox(width: 5),
                      _buildFilterChip('사무실'),
                      const SizedBox(width: 5),
                      _buildFilterChip('단골 카페'),
                    ],
                  ),
                ),
              ),
              
              // Section title with count
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '내가 깨운 사물들',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.32,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF5F5F5), // var(--color-bg-secondary)
                      ),
                      child: const Center(
                        child: Text(
                          '99',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Carousel section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 0, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCard('https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/c6928886c4f0b44052a2256cf7668f5e116f8bda?placeholderIfAbsent=true', '내 방', '디자인 체어', '42'),
                      const SizedBox(width: 12),
                      _buildCard('https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/6fe8836c7fb536ba754ec565ff60d7be5e264bb8?placeholderIfAbsent=true', '사무실', '제임쓰 카페인쓰', '5'),
                      const SizedBox(width: 12),
                      _buildCard('https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/9a27d7152e1f50931592c370d31f9cdff632a77c?placeholderIfAbsent=true', '우리집 안방', '빈백', '139'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFilterChip(String label) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
  
  Widget _buildCard(String imageUrl, String location, String name, String time) {
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(74),
                child: Image.network(
                  imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              if (imageUrl == 'https://cdn.builder.io/api/v1/image/assets/10c3629ee50f4bb7b8873d2a0797b2af/c6928886c4f0b44052a2256cf7668f5e116f8bda?placeholderIfAbsent=true') // Show NEW badge only on first card
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2.476),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 0.413),
                      color: const Color(0xFFFFCF00),
                    ),
                    padding: const EdgeInsets.fromLTRB(4, 2, 3, 2),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 6,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            location,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.black,
            ),
          ),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              color: Colors.black,
              height: 1.4,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: time,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const TextSpan(
                  text: ' ',
                  style: TextStyle(color: Colors.black),
                ),
                const TextSpan(
                  text: 'min',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    fontWeight: FontWeight.w200,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
