class AiChatMessage {
  final int id;
  final String sender; // 'bot' | 'user'
  final String text;
  final List<ChatTableRow>? tableRows;
  final List<SpecialtySelectOption>? specialtySelector;
  final List<DoctorSelectOption>? doctorSelector;
  final List<String>? timeSlotSelector;
  final BookingConfirmData? bookingConfirm;
  final BookingSuccessData? bookingSuccess;

  AiChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.tableRows,
    this.specialtySelector,
    this.doctorSelector,
    this.timeSlotSelector,
    this.bookingConfirm,
    this.bookingSuccess,
  });

  // Chuyển đổi JSON lịch sử trò chuyện để lưu trữ cục bộ
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'tableRows': tableRows?.map((e) => e.toJson()).toList(),
      'specialtySelector': specialtySelector?.map((e) => e.toJson()).toList(),
      'doctorSelector': doctorSelector?.map((e) => e.toJson()).toList(),
      'timeSlotSelector': timeSlotSelector,
      'bookingConfirm': bookingConfirm?.toJson(),
      'bookingSuccess': bookingSuccess?.toJson(),
    };
  }

  factory AiChatMessage.fromJson(Map<String, dynamic> json) {
    return AiChatMessage(
      id: json['id'] as int,
      sender: json['sender'] as String,
      text: json['text'] as String,
      tableRows: (json['tableRows'] as List?)
          ?.map((e) => ChatTableRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      specialtySelector: (json['specialtySelector'] as List?)
          ?.map((e) => SpecialtySelectOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      doctorSelector: (json['doctorSelector'] as List?)
          ?.map((e) => DoctorSelectOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeSlotSelector: (json['timeSlotSelector'] as List?)?.map((e) => e as String).toList(),
      bookingConfirm: json['bookingConfirm'] != null
          ? BookingConfirmData.fromJson(json['bookingConfirm'] as Map<String, dynamic>)
          : null,
      bookingSuccess: json['bookingSuccess'] != null
          ? BookingSuccessData.fromJson(json['bookingSuccess'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ChatTableRow {
  final String label;
  final String value;

  ChatTableRow({required this.label, required this.value});

  Map<String, dynamic> toJson() => {'label': label, 'value': value};

  factory ChatTableRow.fromJson(Map<String, dynamic> json) {
    return ChatTableRow(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

class SpecialtySelectOption {
  final int specialtyId;
  final String specialtyName;

  SpecialtySelectOption({required this.specialtyId, required this.specialtyName});

  Map<String, dynamic> toJson() => {
        'specialtyId': specialtyId,
        'specialtyName': specialtyName,
      };

  factory SpecialtySelectOption.fromJson(Map<String, dynamic> json) {
    return SpecialtySelectOption(
      specialtyId: json['specialtyId'] as int,
      specialtyName: json['specialtyName'] as String? ?? '',
    );
  }
}

class DoctorSelectOption {
  final int doctorId;
  final String doctorName;
  final int examFee;
  final String specialtyName;

  DoctorSelectOption({
    required this.doctorId,
    required this.doctorName,
    required this.examFee,
    required this.specialtyName,
  });

  Map<String, dynamic> toJson() => {
        'doctorId': doctorId,
        'doctorName': doctorName,
        'examFee': examFee,
        'specialtyName': specialtyName,
      };

  factory DoctorSelectOption.fromJson(Map<String, dynamic> json) {
    return DoctorSelectOption(
      doctorId: json['doctorId'] as int,
      doctorName: json['doctorName'] as String? ?? '',
      examFee: json['examFee'] as int? ?? 150000,
      specialtyName: json['specialtyName'] as String? ?? '',
    );
  }
}

class BookingConfirmData {
  final String specialtyName;
  final String doctorName;
  final String dateText;
  final String slotTime;
  final int fee;

  BookingConfirmData({
    required this.specialtyName,
    required this.doctorName,
    required this.dateText,
    required this.slotTime,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'specialtyName': specialtyName,
        'doctorName': doctorName,
        'dateText': dateText,
        'slotTime': slotTime,
        'fee': fee,
      };

  factory BookingConfirmData.fromJson(Map<String, dynamic> json) {
    return BookingConfirmData(
      specialtyName: json['specialtyName'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? '',
      dateText: json['dateText'] as String? ?? '',
      slotTime: json['slotTime'] as String? ?? '',
      fee: json['fee'] as int? ?? 150000,
    );
  }
}

class BookingSuccessData {
  final int appointmentId;
  final String appointmentCode;
  final int fee;

  BookingSuccessData({
    required this.appointmentId,
    required this.appointmentCode,
    required this.fee,
  });

  Map<String, dynamic> toJson() => {
        'appointmentId': appointmentId,
        'appointmentCode': appointmentCode,
        'fee': fee,
      };

  factory BookingSuccessData.fromJson(Map<String, dynamic> json) {
    return BookingSuccessData(
      appointmentId: json['appointmentId'] as int? ?? 0,
      appointmentCode: json['appointmentCode'] as String? ?? '',
      fee: json['fee'] as int? ?? 150000,
    );
  }
}
