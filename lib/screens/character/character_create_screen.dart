import 'package:flutter/material.dart';
import 'package:nompangs/screens/character/character_complete_screen.dart';

class CharacterCreateScreen extends StatefulWidget {
  @override
  _CharacterCreateScreenState createState() => _CharacterCreateScreenState();
}

class _CharacterCreateScreenState extends State<CharacterCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  List<String> _personalityTags = [];

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _personalityTags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  void _removeTag(int index) {
    setState(() {
      _personalityTags.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '캐릭터 만들기',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 캐릭터 이름 입력
                Text(
                  '캐릭터 이름',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '캐릭터의 이름을 입력해주세요',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이름을 입력해주세요';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 30),
                // 성격 태그 입력
                Text(
                  '성격 태그',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: '태그를 입력하고 + 버튼을 눌러주세요',
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.blue),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // 입력된 태그들 표시
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _personalityTags.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(
                        '#${entry.value}',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.blue[700],
                      deleteIcon: Icon(Icons.close, color: Colors.white, size: 18),
                      onDeleted: () => _removeTag(entry.key),
                    );
                  }).toList(),
                ),
                SizedBox(height: 40),
                // 완료 버튼
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() && _personalityTags.isNotEmpty) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CharacterCompleteScreen(
                              characterName: _nameController.text,
                              personalityTags: _personalityTags,
                              greeting: '안녕! 나는 ${_nameController.text}이야~ 잘 부탁해!',
                            ),
                          ),
                        );
                      } else if (_personalityTags.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('최소 하나의 성격 태그를 추가해주세요')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      '캐릭터 만들기',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 