import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:aura/core/constants/aura_colors.dart';

class CreatePlaylistTile extends StatelessWidget {
  const CreatePlaylistTile({super.key, required this.onCreate});

  final ValueChanged<String> onCreate;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.add_circle_outline_rounded, color: AuraColors.primary),
      title: Text('Create new playlist', style: TextStyle(color: AuraColors.text, fontSize: 14.sp)),
      onTap: () => _showCreateDialog(context),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.surfaceHigh,
        title: Text(
          'New Playlist',
          style: TextStyle(color: AuraColors.text, fontSize: 15.sp, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: AuraColors.text),
          decoration: InputDecoration(
            hintText: 'Playlist name',
            hintStyle: TextStyle(color: AuraColors.muted),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AuraColors.primary),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: AuraColors.muted, fontSize: 12.sp, fontWeight: FontWeight.w700)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              Navigator.pop(ctx);
              if (name.isNotEmpty) {
                onCreate(name);
              }
            },
            child: Text('Create', style: TextStyle(color: AuraColors.primary, fontSize: 12.sp, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
