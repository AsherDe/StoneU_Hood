// lib/features/community/widgets/study_material_card.dart
import 'package:flutter/material.dart';
import '../models/study_material.dart';

class StudyMaterialCard extends StatelessWidget {
  final StudyMaterial material;
  final VoidCallback onTap;
  final bool showFavoriteButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const StudyMaterialCard({
    Key? key,
    required this.material,
    required this.onTap,
    this.showFavoriteButton = false,
    this.isFavorite = false,
    this.onFavoriteToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部包含类型标签和收藏按钮
              Row(
                children: [
                  // 类型标签
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: material.materialType.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          material.materialType.icon,
                          size: 16,
                          color: material.materialType.color,
                        ),
                        SizedBox(width: 4),
                        Text(
                          material.materialType.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: material.materialType.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // 收藏按钮（如果启用）
                  if (showFavoriteButton)
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.bookmark : Icons.bookmark_border,
                        color: isFavorite ? Colors.orange : Colors.grey,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                ],
              ),
              SizedBox(height: 12),
              
              // 标题
              Text(
                material.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              
              // 描述
              Text(
                material.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              
              // 底部信息：上传者、日期、下载次数等
              Row(
                children: [
                  // 上传者
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            material.contributor,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 分隔符
                  Container(
                    height: 12,
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                  ),
                  
                  // 上传日期
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatDate(material.uploadDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // 评分、浏览和下载信息
              Row(
                children: [
                  // 评分
                  _buildStat(
                    Icons.star,
                    material.rating.toStringAsFixed(1),
                    Colors.amber,
                  ),
                  SizedBox(width: 16),
                  
                  // 浏览次数
                  _buildStat(
                    Icons.visibility,
                    '${material.viewCount}',
                    Colors.blue.shade300,
                  ),
                  SizedBox(width: 16),
                  
                  // 下载次数
                  _buildStat(
                    Icons.download,
                    '${material.downloadCount}',
                    Colors.green.shade300,
                  ),
                  
                  Spacer(),
                  
                  // 文件或链接指示图标
                  if (material.fileUrl != null)
                    Icon(
                      Icons.insert_drive_file,
                      size: 16,
                      color: Colors.blue.shade400,
                    )
                  else if (material.externalLink != null)
                    Icon(
                      Icons.link,
                      size: 16,
                      color: Colors.purple.shade400,
                    ),
                ],
              ),
              
              // 标签行
              if (material.tags.isNotEmpty) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: material.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      if (difference.inHours < 1) {
        return '${difference.inMinutes}分钟前';
      }
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}