/// Satu pengalaman kerja di CV.
class CvExperience {
  const CvExperience({
    required this.role,
    this.company = '',
    this.period = '',
    this.description = '',
  });

  final String role;
  final String company;
  final String period;
  final String description;

  Map<String, dynamic> toJson() => {
    'role': role,
    'company': company,
    'period': period,
    'description': description,
  };

  factory CvExperience.fromJson(Map<String, dynamic> j) => CvExperience(
    role: j['role'] as String? ?? '',
    company: j['company'] as String? ?? '',
    period: j['period'] as String? ?? '',
    description: j['description'] as String? ?? '',
  );
}

/// Satu riwayat pendidikan di CV.
class CvEducation {
  const CvEducation({required this.school, this.major = '', this.period = ''});

  final String school;
  final String major;
  final String period;

  Map<String, dynamic> toJson() => {
    'school': school,
    'major': major,
    'period': period,
  };

  factory CvEducation.fromJson(Map<String, dynamic> j) => CvEducation(
    school: j['school'] as String? ?? '',
    major: j['major'] as String? ?? '',
    period: j['period'] as String? ?? '',
  );
}

/// CV pengguna. Susunannya mengikuti CV umum di Indonesia dan internasional:
/// data diri, ringkasan, pengalaman, pendidikan, keahlian, bahasa,
/// sertifikat, dan tautan portofolio.
class CvData {
  const CvData({
    this.fullName = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.city = '',
    this.summary = '',
    this.experiences = const [],
    this.educations = const [],
    this.skills = const [],
    this.languages = const [],
    this.certifications = const [],
    this.links = const [],
    this.updatedAt,
  });

  final String fullName;

  /// Posisi yang dicari atau jabatan saat ini, mis. "Backend Developer".
  final String headline;
  final String email;
  final String phone;
  final String city;
  final String summary;
  final List<CvExperience> experiences;
  final List<CvEducation> educations;
  final List<String> skills;
  final List<String> languages;
  final List<String> certifications;
  final List<String> links;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'headline': headline,
    'email': email,
    'phone': phone,
    'city': city,
    'summary': summary,
    'experiences': [for (final e in experiences) e.toJson()],
    'educations': [for (final e in educations) e.toJson()],
    'skills': skills,
    'languages': languages,
    'certifications': certifications,
    'links': links,
  };

  factory CvData.fromJson(Map<String, dynamic> j, {DateTime? updatedAt}) {
    List<String> strings(String key) => [
      for (final v in (j[key] as List? ?? const [])) v.toString(),
    ];
    List<Map<String, dynamic>> maps(String key) => [
      for (final v in (j[key] as List? ?? const []))
        Map<String, dynamic>.from(v as Map),
    ];

    return CvData(
      fullName: j['fullName'] as String? ?? '',
      headline: j['headline'] as String? ?? '',
      email: j['email'] as String? ?? '',
      phone: j['phone'] as String? ?? '',
      city: j['city'] as String? ?? '',
      summary: j['summary'] as String? ?? '',
      experiences: maps('experiences').map(CvExperience.fromJson).toList(),
      educations: maps('educations').map(CvEducation.fromJson).toList(),
      skills: strings('skills'),
      languages: strings('languages'),
      certifications: strings('certifications'),
      links: strings('links'),
      updatedAt: updatedAt,
    );
  }
}
