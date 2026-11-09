import 'dart:convert';
import 'dart:io';

import '../domain/catalog_validation.dart';
import '../domain/dreams_catalog.dart';

class CatalogLoadException implements Exception {
  final String message;
  final Object? cause;

  const CatalogLoadException(this.message, [this.cause]);

  @override
  String toString() => cause == null ? message : '$message: $cause';
}

typedef CatalogTextReader = Future<String> Function(String path);

class DreamsCatalogLoader {
  final CatalogValidator validator;
  final CatalogTextReader readText;

  DreamsCatalogLoader({
    CatalogValidator? validator,
    CatalogTextReader? readText,
  })  : validator = validator ?? const CatalogValidator(),
        readText = readText ?? _readFile;

  Future<DreamsCatalog> loadFile(String path) async {
    late final String contents;
    try {
      contents = await readText(path);
    } on FileSystemException catch (error) {
      throw CatalogLoadException(
          'Catalog file could not be read: $path', error);
    }
    return loadString(contents, origin: path);
  }

  DreamsCatalog loadString(String contents, {String origin = 'memory'}) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(contents);
    } on FormatException catch (error) {
      throw CatalogLoadException('Catalog JSON is corrupt at $origin', error);
    }
    if (decoded is! Map) {
      throw CatalogLoadException(
        'Catalog root must be a JSON object at $origin',
      );
    }

    late final DreamsCatalog catalog;
    try {
      final json = Map<String, dynamic>.from(decoded);
      _validateKnownFields(json);
      catalog = DreamsCatalog.fromJson(json);
    } on FormatException catch (error) {
      throw CatalogLoadException('Catalog schema is invalid at $origin', error);
    } on TypeError catch (error) {
      throw CatalogLoadException('Catalog schema is invalid at $origin', error);
    }

    final issues = validator.validate(catalog);
    if (issues.isNotEmpty) throw CatalogValidationException(issues);
    return catalog;
  }

  static Future<String> _readFile(String path) => File(path).readAsString();

  static void _validateKnownFields(Map<String, dynamic> json) {
    _rejectUnknown(
        json,
        const {
          'metadata',
          'sources',
          'entries',
          'claims',
          'interpretations',
          'conflictGroups',
          'rightsEvidence',
          'articles',
        },
        'catalog');
    _validateObject(
        json['metadata'],
        const {
          'schemaVersion',
          'catalogVersion',
          'locale',
          'generatedAt',
          'editorialStatus',
        },
        'metadata');
    _validateList(
        json['sources'],
        const {
          'id',
          'title',
          'author',
          'publisher',
          'url',
          'publicationDate',
          'accessDate',
          'sourceType',
          'jurisdiction',
          'rightsStatus',
          'verificationStatus',
        },
        'sources');
    _validateList(
        json['entries'],
        const {
          'id',
          'canonicalTerm',
          'category',
          'description',
          'variants',
        },
        'entries', nested: (item, index) {
      _validateList(
          item['variants'],
          const {
            'term',
            'relationType',
            'context',
            'locale',
          },
          'entries[$index].variants');
    });
    _validateList(
        json['claims'],
        const {
          'id',
          'catalogEntryId',
          'number',
          'sourceId',
          'sourceLocation',
          'verificationStatus',
          'notes',
          'rightsEvidenceIds',
        },
        'claims');
    _validateList(
        json['interpretations'],
        const {
          'id',
          'catalogEntryId',
          'text',
          'sourceReferences',
          'verificationStatus',
          'publicationStatus',
          'rightsEvidenceIds',
        },
        'interpretations');
    _validateList(
        json['conflictGroups'],
        const {
          'id',
          'claimIds',
          'conflictType',
          'explanation',
        },
        'conflictGroups');
    _validateList(
        json['rightsEvidence'],
        const {
          'id',
          'sourceId',
          'rightsHolder',
          'authorizationType',
          'evidenceReference',
          'evidenceDate',
          'validFrom',
          'validUntil',
          'indefiniteTermJustification',
          'territory',
          'territories',
          'commercialUseAllowed',
          'redistributionAllowed',
          'derivativeWorksAllowed',
          'attributionRequired',
          'restrictions',
          'reviewStatus',
          'reviewedAt',
          'scopeType',
          'scopeReferences',
          'legalBasisType',
          'authorshipReference',
          'originalityDeclaration',
          'editorialReviewReference',
          'historicalFactReferences',
          'unauthorizedReproductionConfirmedAbsent',
          'licenseIdentifier',
          'licenseVersion',
          'licenseUrl',
          'licenseConditions',
          'attributionReference',
          'legalJurisdiction',
          'legalException',
          'legalReviewReference',
          'legalReviewerRole',
          'legalConclusionDate',
          'legalLimitations',
        },
        'rightsEvidence');
    _validateList(
        json['articles'],
        const {
          'id',
          'title',
          'category',
          'text',
          'sourceReferences',
          'rightsEvidenceIds',
          'verificationStatus',
          'rightsStatus',
          'publicationStatus',
          'reviewedAt',
        },
        'articles');
  }

  static void _validateObject(
    Object? value,
    Set<String> allowed,
    String path,
  ) {
    if (value is Map) {
      _rejectUnknown(Map<String, dynamic>.from(value), allowed, path);
    }
  }

  static void _validateList(
    Object? value,
    Set<String> allowed,
    String path, {
    void Function(Map<String, dynamic> item, int index)? nested,
  }) {
    if (value is! List) return;
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! Map) continue;
      final object = Map<String, dynamic>.from(item);
      _rejectUnknown(object, allowed, '$path[$index]');
      nested?.call(object, index);
    }
  }

  static void _rejectUnknown(
    Map<String, dynamic> value,
    Set<String> allowed,
    String path,
  ) {
    final unknown = value.keys.where((key) => !allowed.contains(key)).toList();
    if (unknown.isNotEmpty) {
      throw FormatException(
        '$path contains unsupported fields: ${unknown.join(', ')}.',
      );
    }
  }
}
