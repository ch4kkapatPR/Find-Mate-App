import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';

class CreatePostPage extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCreate;
  final ActivityItem? activity;

  const CreatePostPage({
    super.key,
    this.onCreate,
    this.activity,
  });

  bool get isEdit => activity != null;

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController detailController = TextEditingController();
  final TextEditingController participantController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  final List<String> categories = [
    'เดินป่า',
    'กีฬา',
    'เรียน',
    'กินข้าว',
    'อื่นๆ',
  ];

  String selectedCategory = 'เดินป่า';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime;
  File? selectedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final activity = widget.activity;
    if (activity != null) {
      titleController.text = activity.title;
      locationController.text = activity.location;
      detailController.text = activity.description;
      participantController.text = activity.total.toString();

      if (categories.contains(activity.category)) {
        selectedCategory = activity.category;
      }

      selectedDate = _parseDateText(activity.dateText);
      selectedTime = _parseTimeText(activity.timeText);
      selectedEndTime = _parseTimeText(activity.endTimeText);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    locationController.dispose();
    detailController.dispose();
    participantController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    setState(() {
      selectedImage = File(image.path);
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var initialDate = selectedDate ?? today;
    if (initialDate.isBefore(today)) {
      initialDate = today;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: DateTime(2035, 12, 31),
      helpText: 'เลือกวันที่จัดกิจกรรม',
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
    );

    if (date == null || !mounted) return;

    setState(() {
      selectedDate = date;
    });
  }

  Future<TimeOfDay?> _show24HourTimePicker({
    required TimeOfDay initialTime,
    required String helpText,
  }) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText,
      cancelText: 'ยกเลิก',
      confirmText: 'เลือก',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Future<void> _pickStartTime() async {
    final time = await _show24HourTimePicker(
      initialTime: selectedTime ?? TimeOfDay.now(),
      helpText: 'เลือกเวลาเริ่มกิจกรรม',
    );

    if (time == null || !mounted) return;

    setState(() {
      selectedTime = time;

      if (selectedEndTime != null &&
          _minutesOfDay(selectedEndTime!) <= _minutesOfDay(time)) {
        selectedEndTime = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    final fallbackStart = selectedTime ?? TimeOfDay.now();
    final defaultEndMinutes = (_minutesOfDay(fallbackStart) + 60).clamp(0, 1439);

    final initialEndTime = selectedEndTime ??
        TimeOfDay(
          hour: defaultEndMinutes ~/ 60,
          minute: defaultEndMinutes % 60,
        );

    final time = await _show24HourTimePicker(
      initialTime: initialEndTime,
      helpText: 'เลือกเวลาสิ้นสุดกิจกรรม',
    );

    if (time == null || !mounted) return;

    setState(() {
      selectedEndTime = time;
    });
  }

  DateTime? _parseDateText(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    try {
      final parts = value.split(RegExp(r'\s+'));

      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);

        const months = <String, int>{
          'ม.ค.': 1,
          'ก.พ.': 2,
          'มี.ค.': 3,
          'เม.ย.': 4,
          'พ.ค.': 5,
          'มิ.ย.': 6,
          'ก.ค.': 7,
          'ส.ค.': 8,
          'ก.ย.': 9,
          'ต.ค.': 10,
          'พ.ย.': 11,
          'ธ.ค.': 12,
        };

        final month = months[parts[1]];
        var year = int.tryParse(parts[2]);

        if (day != null && month != null && year != null) {
          if (year > 2400) year -= 543;
          return DateTime(year, month, day);
        }
      }

      final normalized = value.replaceAll('-', '/');
      final slashParts = normalized.split('/');

      if (slashParts.length == 3) {
        final day = int.tryParse(slashParts[0].trim());
        final month = int.tryParse(slashParts[1].trim());
        var year = int.tryParse(slashParts[2].trim());

        if (day == null || month == null || year == null) return null;
        if (year > 2400) year -= 543;

        return DateTime(year, month, day);
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  TimeOfDay? _parseTimeText(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;

    final match = RegExp(r'(\d{1,2})\s*:\s*(\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDate(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute น.';
  }

  int _minutesOfDay(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  DateTime? _selectedStartDateTime() {
    if (selectedDate == null || selectedTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  DateTime? _selectedEndDateTime() {
    if (selectedDate == null || selectedEndTime == null) return null;

    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedEndTime!.hour,
      selectedEndTime!.minute,
    );
  }

  Future<void> _saveActivity() async {
    if (_isSaving) return;

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    if (selectedDate == null) {
      _showMessage('กรุณาเลือกวันที่จัดกิจกรรม');
      return;
    }

    if (selectedTime == null) {
      _showMessage('กรุณาเลือกเวลาเริ่มกิจกรรม');
      return;
    }

    if (selectedEndTime == null) {
      _showMessage('กรุณาเลือกเวลาสิ้นสุดกิจกรรม');
      return;
    }

    final startDateTime = _selectedStartDateTime();
    final endDateTime = _selectedEndDateTime();

    if (startDateTime == null || endDateTime == null) {
      _showMessage('วันที่หรือเวลาของกิจกรรมไม่ถูกต้อง');
      return;
    }

    if (!widget.isEdit && !startDateTime.isAfter(DateTime.now())) {
      _showMessage('วันที่และเวลาเริ่มกิจกรรมต้องเป็นเวลาในอนาคต');
      return;
    }

    if (!endDateTime.isAfter(startDateTime)) {
      _showMessage('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม');
      return;
    }

    final total = int.tryParse(participantController.text.trim());
    if (total == null || total < 2) {
      _showMessage('จำนวนผู้เข้าร่วมต้องมีอย่างน้อย 2 คน');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final oldActivity = widget.activity;
      final formattedDate = _formatDate(selectedDate!);
      final formattedStartTime = _formatTime(selectedTime!);
      final formattedEndTime = _formatTime(selectedEndTime!);

      if (oldActivity != null) {
        if (oldActivity.id.isEmpty) {
          throw Exception('ไม่พบ Activity ID');
        }

        final updatedActivity = ActivityItem(
          id: oldActivity.id,
          title: titleController.text.trim(),
          category: selectedCategory,
          joined: oldActivity.joined,
          total: total,
          dateText: formattedDate,
          timeText: formattedStartTime,
          endTimeText: formattedEndTime,
          location: locationController.text.trim(),
          image: selectedImage?.path ?? oldActivity.image,
          description: detailController.text.trim(),
          images: oldActivity.images,
          isOwner: oldActivity.isOwner,
          isJoined: oldActivity.isJoined,
        );

        await FirestoreActivityService.updateActivity(updatedActivity);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('แก้ไขกิจกรรมเรียบร้อยแล้ว')),
        );
        Navigator.pop(context, true);
        return;
      }

      final newActivity = ActivityItem(
        title: titleController.text.trim(),
        category: selectedCategory,
        joined: 1,
        total: total,
        dateText: formattedDate,
        timeText: formattedStartTime,
        endTimeText: formattedEndTime,
        location: locationController.text.trim(),
        image: selectedImage?.path ?? '',
        description: detailController.text.trim(),
        isOwner: true,
        isJoined: true,
      );

      await FirestoreActivityService.createActivity(newActivity);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างกิจกรรมเรียบร้อยแล้ว')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _showMessage('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isEdit ? 'แก้ไขกิจกรรม' : 'สร้างกิจกรรม',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    selectedImage!,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                )
                    : _oldImageWidget(),
              ),
            ),
            const SizedBox(height: 22),

            _buildLabel('ชื่อกิจกรรม'),
            TextFormField(
              controller: titleController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'เช่น เดินป่าเขาใหญ่',
                Icons.title_rounded,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาใส่ชื่อกิจกรรม';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildLabel('หมวดหมู่'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 18),

            _buildLabel('จำนวนผู้เข้าร่วมสูงสุด'),
            TextFormField(
              controller: participantController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'เช่น 5',
                Icons.people_alt_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุจำนวนผู้เข้าร่วม';
                }

                final number = int.tryParse(value.trim());
                if (number == null) return 'กรุณากรอกเป็นตัวเลข';
                if (number < 2) return 'จำนวนผู้เข้าร่วมต้องมีอย่างน้อย 2 คน';
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildLabel('วันที่จัดกิจกรรม'),
            _buildPickerBox(
              icon: Icons.calendar_month_rounded,
              text: selectedDate == null
                  ? 'เลือกวันที่'
                  : _formatDate(selectedDate!),
              selected: selectedDate != null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 18),

            _buildLabel('เวลาเริ่มกิจกรรม'),
            _buildPickerBox(
              icon: Icons.access_time_rounded,
              text: selectedTime == null
                  ? 'เลือกเวลาเริ่ม'
                  : _formatTime(selectedTime!),
              selected: selectedTime != null,
              onTap: _pickStartTime,
            ),
            const SizedBox(height: 18),

            _buildLabel('เวลาสิ้นสุดกิจกรรม'),
            _buildPickerBox(
              icon: Icons.timer_outlined,
              text: selectedEndTime == null
                  ? 'เลือกเวลาสิ้นสุด'
                  : _formatTime(selectedEndTime!),
              selected: selectedEndTime != null,
              onTap: _pickEndTime,
            ),
            const SizedBox(height: 8),

            const Row(
              children: [
                SizedBox(width: 4),
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม และต้องเป็นวันเดียวกัน',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            _buildLabel('สถานที่'),
            TextFormField(
              controller: locationController,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(
                'เช่น อุทยานแห่งชาติเขาใหญ่',
                Icons.location_on_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาระบุสถานที่';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),

            _buildLabel('รายละเอียด'),
            TextFormField(
              controller: detailController,
              minLines: 4,
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              decoration: _inputDecoration(
                'รายละเอียดเพิ่มเติมของกิจกรรม',
                Icons.description_outlined,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณาใส่รายละเอียดกิจกรรม';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveActivity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C4DFF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB7AAFF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  isEdit ? 'บันทึกการแก้ไข' : 'สร้างกิจกรรม',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerBox({
    required IconData icon,
    required String text,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6C4DFF)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: selected ? Colors.black87 : Colors.grey,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _oldImageWidget() {
    final image = widget.activity?.image ?? '';

    if (image.isEmpty) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 45,
            color: Color(0xFF6C4DFF),
          ),
          SizedBox(height: 8),
          Text(
            'เพิ่มรูปภาพกิจกรรม',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    if (image.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          image,
          width: double.infinity,
          height: 190,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _brokenImageWidget();
          },
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.file(
        File(image),
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _brokenImageWidget();
        },
      ),
    );
  }

  Widget _brokenImageWidget() {
    return const Center(
      child: Icon(
        Icons.broken_image_outlined,
        size: 45,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF6C4DFF),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF6C4DFF),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
    );
  }
}
