import 'package:json_annotation/json_annotation.dart';
import 'package:talao/app/shared/model/credential_manifest/color_object.dart';
import 'package:talao/app/shared/model/credential_manifest/image_object.dart';

part 'styles.g.dart';

@JsonSerializable(explicitToJson: true)
class Styles {
  Styles(this.thumbnail, this.hero, this.background, this.text);

  factory Styles.fromJson(Map<String, dynamic> json) => _$StylesFromJson(json);

  final ImageObject? thumbnail;
  final ImageObject? hero;
  final ColorObject? background;
  final ColorObject? text;

  Map<String, dynamic> toJson() => _$StylesToJson(this);
}
