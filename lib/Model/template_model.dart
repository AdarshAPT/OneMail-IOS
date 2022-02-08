class TemplateModel {
  final String templateHeader;
  final String templateBody;

  TemplateModel({required this.templateBody, required this.templateHeader});

  factory TemplateModel.fromJSON(Map json) {
    return TemplateModel(
        templateHeader: json['templateHeader'],
        templateBody: json['templateBody']);
  }
}
