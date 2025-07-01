 enum ProtocolType {
  mqtt,
  mqtts,
}

enum CertificateType {
  caSigned,
  selfSigned,
}

class SslConfig {
  final ProtocolType protocolType;
  final bool sslEnabled;
  final bool verifyServerCertificate;
  final CertificateType certificateType;
  final String? caFilePath;
  final String? clientCertPath;
  final String? clientKeyPath;

  SslConfig({
    this.protocolType = ProtocolType.mqtt,
    this.sslEnabled = false,
    this.verifyServerCertificate = true,
    this.certificateType = CertificateType.caSigned,
    this.caFilePath,
    this.clientCertPath,
    this.clientKeyPath,
  });

  SslConfig copyWith({
    ProtocolType? protocolType,
    bool? sslEnabled,
    bool? verifyServerCertificate,
    CertificateType? certificateType,
    String? caFilePath,
    String? clientCertPath,
    String? clientKeyPath,
  }) {
    return SslConfig(
      protocolType: protocolType ?? this.protocolType,
      sslEnabled: sslEnabled ?? this.sslEnabled,
      verifyServerCertificate: verifyServerCertificate ?? this.verifyServerCertificate,
      certificateType: certificateType ?? this.certificateType,
      caFilePath: caFilePath ?? this.caFilePath,
      clientCertPath: clientCertPath ?? this.clientCertPath,
      clientKeyPath: clientKeyPath ?? this.clientKeyPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocolType': protocolType.name,
      'sslEnabled': sslEnabled,
      'verifyServerCertificate': verifyServerCertificate,
      'certificateType': certificateType.name,
      'caFilePath': caFilePath,
      'clientCertPath': clientCertPath,
      'clientKeyPath': clientKeyPath,
    };
  }

  factory SslConfig.fromJson(Map<String, dynamic> json) {
    return SslConfig(
      protocolType: ProtocolType.values.firstWhere(
        (e) => e.name == json['protocolType'],
        orElse: () => ProtocolType.mqtt,
      ),
      sslEnabled: json['sslEnabled'] ?? false,
      verifyServerCertificate: json['verifyServerCertificate'] ?? true,
      certificateType: CertificateType.values.firstWhere(
        (e) => e.name == json['certificateType'],
        orElse: () => CertificateType.caSigned,
      ),
      caFilePath: json['caFilePath'],
      clientCertPath: json['clientCertPath'],
      clientKeyPath: json['clientKeyPath'],
    );
  }
}