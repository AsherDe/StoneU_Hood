// lib/features/community/screens/study_materials_screen.dart
import 'package:flutter/material.dart' hide MaterialType;
import '../models/study_material.dart';
import '../widgets/study_material_card.dart';
import '../widgets/filter_chip_list.dart';
import '../services/community_service.dart';

class StudyMaterialsScreen extends StatefulWidget {
  @override
  _StudyMaterialsScreenState createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final CommunityService _communityService = CommunityService();
  List<StudyMaterial> _materials = [];
  List<StudyMaterial> _filteredMaterials = [];
  bool _isLoading = true;
  StudyMaterialType? _selectedType;
  String _searchQuery = '';
  String? _selectedSubject;
  List<String> _availableSubjects = [];
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final materials = await _communityService.getStudyMaterials();
      
      // Extract unique subjects
      final subjects = materials.map((m) => m.subject).toSet().toList();
      subjects.sort();
      
      setState(() {
        _materials = materials;
        _availableSubjects = subjects;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载学习资料失败: $e')),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMaterials = _materials.where((material) {
        // Apply material type filter
        if (_selectedType != null && material.materialType != _selectedType) {
          return false;
        }
        
        // Apply subject filter
        if (_selectedSubject != null && material.subject != _selectedSubject) {
          return false;
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          return material.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              material.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              material.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()));
        }
        
        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '学习资料',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.tune),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索学习资料...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Filter chips for material types
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipList<StudyMaterialType>(
              items: StudyMaterialType.values,
              selectedItem: _selectedType,
              getLabel: (type) => type.name,
              onSelected: (type) {
                setState(() {
                  if (_selectedType == type) {
                    _selectedType = null;
                  } else {
                    _selectedType = type;
                  }
                  _applyFilters();
                });
              },
            ),
          ),
          
          // Subject selector
          if (_availableSubjects.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text('选择学科'),
                    value: _selectedSubject,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSubject = newValue;
                        _applyFilters();
                      });
                    },
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('所有学科'),
                      ),
                      ..._availableSubjects.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          
          // Results count
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '找到 ${_filteredMaterials.length} 个资料',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Materials list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredMaterials.isEmpty
                    ? Center(
                        child: Text(
                          '没有找到符合条件的资料',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMaterials,
                        child: ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _filteredMaterials.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 16),
                              child: StudyMaterialCard(
                                material: _filteredMaterials[index],
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudyMaterialDetailScreen(
                                        material: _filteredMaterials[index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create study material screen
        },
        child: Icon(Icons.add),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '排序和筛选',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.sort),
              title: Text('最新上传'),
              onTap: () {
                Navigator.pop(context);
                // Sort by newest
                setState(() {
                  _materials.sort((a, b) => b.uploadDate.compareTo(a.uploadDate));
                  _applyFilters();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.trending_down),
              title: Text('最多下载'),
              onTap: () {
                Navigator.pop(context);
                // Sort by download count
                setState(() {
                  _materials.sort((a, b) => b.downloadCount.compareTo(a.downloadCount));
                  _applyFilters();
                });
              },
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text('最高评分'),
              onTap: () {
                Navigator.pop(context);
                // Sort by rating
                setState(() {
                  _materials.sort((a, b) => b.rating.compareTo(a.rating));
                  _applyFilters();
                });
              },
            ),
            SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

class StudyMaterialDetailScreen extends StatelessWidget {
  final StudyMaterial material;

  const StudyMaterialDetailScreen({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '资料详情',
          style: TextStyle(color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.bookmark_border),
            onPressed: () {
              // TODO: Implement bookmark functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with type icon and title
            Container(
              padding: EdgeInsets.all(20),
              color: material.materialType.color.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: material.materialType.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          material.materialType.icon,
                          color: material.materialType.color,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            material.materialType.name,
                            style: TextStyle(
                              color: material.materialType.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            material.subject,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Text(
                    material.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        material.contributor,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(material.uploadDate),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Material stats (views, downloads, rating)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(Icons.visibility, '${material.viewCount} 浏览'),
                  _buildStat(Icons.download, '${material.downloadCount} 下载'),
                  _buildStat(Icons.star, '${material.rating.toStringAsFixed(1)} 评分'),
                ],
              ),
            ),
            
            // Description
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '描述',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    material.description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Tags
                  if (material.tags.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '标签',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: material.tags.map((tag) => _buildTag(tag)).toList(),
                        ),
                        SizedBox(height: 24),
                      ],
                    ),
                  
                  // External link if available
                  if (material.externalLink != null && material.externalLink!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '外部链接',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            // TODO: Open external link
                          },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.link, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    material.externalLink!,
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              if (material.fileUrl != null && material.fileUrl!.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement download
                    },
                    icon: Icon(Icons.download),
                    label: Text('下载'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (material.fileUrl != null && material.fileUrl!.isNotEmpty && 
                  material.externalLink != null && material.externalLink!.isNotEmpty)
                SizedBox(width: 16),
              if (material.externalLink != null && material.externalLink!.isNotEmpty)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Open external link
                    },
                    icon: Icon(Icons.open_in_new),
                    label: Text('打开链接'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}