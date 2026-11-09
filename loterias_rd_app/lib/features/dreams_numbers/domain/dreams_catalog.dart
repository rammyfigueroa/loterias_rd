enum RightsStatus {
  authorized,
  openLicense,
  permissionPending,
  unauthorized,
  restricted,
  unknown,
}

enum VerificationStatus {
  verified,
  supported,
  disputed,
  unverified,
  rejected,
}

enum PublicationStatus { draft, review, approved, rejected }

enum RightsReviewStatus { pending, approved, rejected }

enum AuthorizationType {
  writtenPermission,
  contract,
  openLicense,
  publicDomain,
  other,
}

enum LegalBasisType {
  explicitPermission,
  originalWork,
  compatibleOpenLicense,
  reviewedLegalException,
}

enum RightsScopeType {
  fullSource,
  specificFragment,
  table,
  article,
  image,
  editorialText,
  structuredData,
  other,
}

enum TerritoryScope { dominicanRepublic, worldwide, specificTerritories }

enum RelationType { exact, synonym, related, narrower, broader, phrase }

enum ConflictType { numericAssociation, terminology, provenance, other }

T _enumValue<T extends Enum>(
  Object? value,
  List<T> values,
  String field,
) {
  if (value is! String) throw FormatException('$field must be a string.');
  for (final item in values) {
    if (item.name == value) return item;
  }
  throw FormatException('$field has an unsupported value: $value.');
}

String _requiredText(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value;
}

String? _optionalText(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) throw FormatException('$field must be a string.');
  return value;
}

List<String> _stringList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a list of strings.');
  }
  return value.cast<String>();
}

List<String> _optionalStringList(Map<String, dynamic> json, String field) {
  if (json[field] == null) return const [];
  return _stringList(json, field);
}

bool _requiredBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

bool? _optionalBool(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! bool) throw FormatException('$field must be a boolean.');
  return value;
}

T? _optionalEnumValue<T extends Enum>(
  Object? value,
  List<T> values,
  String field,
) {
  if (value == null) return null;
  return _enumValue(value, values, field);
}

class Source {
  final String id;
  final String title;
  final String? author;
  final String? publisher;
  final String? url;
  final String? publicationDate;
  final String accessDate;
  final String sourceType;
  final String jurisdiction;
  final RightsStatus rightsStatus;
  final VerificationStatus verificationStatus;

  const Source({
    required this.id,
    required this.title,
    required this.author,
    required this.publisher,
    required this.url,
    required this.publicationDate,
    required this.accessDate,
    required this.sourceType,
    required this.jurisdiction,
    required this.rightsStatus,
    required this.verificationStatus,
  });

  factory Source.fromJson(Map<String, dynamic> json) => Source(
        id: _requiredText(json, 'id'),
        title: _requiredText(json, 'title'),
        author: _optionalText(json, 'author'),
        publisher: _optionalText(json, 'publisher'),
        url: _optionalText(json, 'url'),
        publicationDate: _optionalText(json, 'publicationDate'),
        accessDate: _requiredText(json, 'accessDate'),
        sourceType: _requiredText(json, 'sourceType'),
        jurisdiction: _requiredText(json, 'jurisdiction'),
        rightsStatus: _enumValue(
          json['rightsStatus'],
          RightsStatus.values,
          'rightsStatus',
        ),
        verificationStatus: _enumValue(
          json['verificationStatus'],
          VerificationStatus.values,
          'verificationStatus',
        ),
      );
}

class RightsEvidence {
  final String id;
  final String sourceId;
  final String rightsHolder;
  final AuthorizationType authorizationType;
  final String evidenceReference;
  final String evidenceDate;
  final String validFrom;
  final String? validUntil;
  final String? indefiniteTermJustification;
  final TerritoryScope territory;
  final List<String> territories;
  final bool commercialUseAllowed;
  final bool redistributionAllowed;
  final bool derivativeWorksAllowed;
  final bool attributionRequired;
  final List<String> restrictions;
  final RightsReviewStatus reviewStatus;
  final String reviewedAt;
  final RightsScopeType scopeType;
  final List<String> scopeReferences;
  final LegalBasisType? legalBasisType;
  final String? authorshipReference;
  final String? originalityDeclaration;
  final String? editorialReviewReference;
  final List<String> historicalFactReferences;
  final bool? unauthorizedReproductionConfirmedAbsent;
  final String? licenseIdentifier;
  final String? licenseVersion;
  final String? licenseUrl;
  final List<String> licenseConditions;
  final String? attributionReference;
  final String? legalJurisdiction;
  final String? legalException;
  final String? legalReviewReference;
  final String? legalReviewerRole;
  final String? legalConclusionDate;
  final List<String> legalLimitations;

  const RightsEvidence({
    required this.id,
    required this.sourceId,
    required this.rightsHolder,
    required this.authorizationType,
    required this.evidenceReference,
    required this.evidenceDate,
    required this.validFrom,
    required this.validUntil,
    required this.indefiniteTermJustification,
    required this.territory,
    required this.territories,
    required this.commercialUseAllowed,
    required this.redistributionAllowed,
    required this.derivativeWorksAllowed,
    required this.attributionRequired,
    required this.restrictions,
    required this.reviewStatus,
    required this.reviewedAt,
    required this.scopeType,
    required this.scopeReferences,
    this.legalBasisType,
    this.authorshipReference,
    this.originalityDeclaration,
    this.editorialReviewReference,
    this.historicalFactReferences = const [],
    this.unauthorizedReproductionConfirmedAbsent,
    this.licenseIdentifier,
    this.licenseVersion,
    this.licenseUrl,
    this.licenseConditions = const [],
    this.attributionReference,
    this.legalJurisdiction,
    this.legalException,
    this.legalReviewReference,
    this.legalReviewerRole,
    this.legalConclusionDate,
    this.legalLimitations = const [],
  });

  factory RightsEvidence.fromJson(Map<String, dynamic> json) => RightsEvidence(
        id: _requiredText(json, 'id'),
        sourceId: _requiredText(json, 'sourceId'),
        rightsHolder: _requiredText(json, 'rightsHolder'),
        authorizationType: _enumValue(
          json['authorizationType'],
          AuthorizationType.values,
          'authorizationType',
        ),
        evidenceReference: _requiredText(json, 'evidenceReference'),
        evidenceDate: _requiredText(json, 'evidenceDate'),
        validFrom: _requiredText(json, 'validFrom'),
        validUntil: _optionalText(json, 'validUntil'),
        indefiniteTermJustification:
            _optionalText(json, 'indefiniteTermJustification'),
        territory: _enumValue(
          json['territory'],
          TerritoryScope.values,
          'territory',
        ),
        territories: _optionalStringList(json, 'territories'),
        commercialUseAllowed: _requiredBool(json, 'commercialUseAllowed'),
        redistributionAllowed: _requiredBool(json, 'redistributionAllowed'),
        derivativeWorksAllowed: _requiredBool(json, 'derivativeWorksAllowed'),
        attributionRequired: _requiredBool(json, 'attributionRequired'),
        restrictions: _optionalStringList(json, 'restrictions'),
        reviewStatus: _enumValue(
          json['reviewStatus'],
          RightsReviewStatus.values,
          'reviewStatus',
        ),
        reviewedAt: _requiredText(json, 'reviewedAt'),
        scopeType: _enumValue(
          json['scopeType'],
          RightsScopeType.values,
          'scopeType',
        ),
        scopeReferences: _stringList(json, 'scopeReferences'),
        legalBasisType: _optionalEnumValue(
          json['legalBasisType'],
          LegalBasisType.values,
          'legalBasisType',
        ),
        authorshipReference: _optionalText(json, 'authorshipReference'),
        originalityDeclaration: _optionalText(json, 'originalityDeclaration'),
        editorialReviewReference:
            _optionalText(json, 'editorialReviewReference'),
        historicalFactReferences:
            _optionalStringList(json, 'historicalFactReferences'),
        unauthorizedReproductionConfirmedAbsent:
            _optionalBool(json, 'unauthorizedReproductionConfirmedAbsent'),
        licenseIdentifier: _optionalText(json, 'licenseIdentifier'),
        licenseVersion: _optionalText(json, 'licenseVersion'),
        licenseUrl: _optionalText(json, 'licenseUrl'),
        licenseConditions: _optionalStringList(json, 'licenseConditions'),
        attributionReference: _optionalText(json, 'attributionReference'),
        legalJurisdiction: _optionalText(json, 'legalJurisdiction'),
        legalException: _optionalText(json, 'legalException'),
        legalReviewReference: _optionalText(json, 'legalReviewReference'),
        legalReviewerRole: _optionalText(json, 'legalReviewerRole'),
        legalConclusionDate: _optionalText(json, 'legalConclusionDate'),
        legalLimitations: _optionalStringList(json, 'legalLimitations'),
      );
}

class TermVariant {
  final String term;
  final RelationType relationType;
  final String? context;
  final String locale;

  const TermVariant({
    required this.term,
    required this.relationType,
    required this.context,
    required this.locale,
  });

  factory TermVariant.fromJson(Map<String, dynamic> json) => TermVariant(
        term: _requiredText(json, 'term'),
        relationType: _enumValue(
          json['relationType'],
          RelationType.values,
          'relationType',
        ),
        context: _optionalText(json, 'context'),
        locale: _requiredText(json, 'locale'),
      );
}

class CatalogEntry {
  final String id;
  final String canonicalTerm;
  final String category;
  final String description;
  final List<TermVariant> variants;

  const CatalogEntry({
    required this.id,
    required this.canonicalTerm,
    required this.category,
    required this.description,
    required this.variants,
  });

  factory CatalogEntry.fromJson(Map<String, dynamic> json) {
    final variants = json['variants'];
    if (variants is! List) {
      throw const FormatException('variants must be a list.');
    }
    return CatalogEntry(
      id: _requiredText(json, 'id'),
      canonicalTerm: _requiredText(json, 'canonicalTerm'),
      category: _requiredText(json, 'category'),
      description: _requiredText(json, 'description'),
      variants: variants
          .map((item) => TermVariant.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(),
    );
  }
}

class DocumentaryClaim {
  final String id;
  final String catalogEntryId;
  final String number;
  final String sourceId;
  final String sourceLocation;
  final VerificationStatus verificationStatus;
  final String? notes;
  final List<String> rightsEvidenceIds;

  const DocumentaryClaim({
    required this.id,
    required this.catalogEntryId,
    required this.number,
    required this.sourceId,
    required this.sourceLocation,
    required this.verificationStatus,
    required this.notes,
    this.rightsEvidenceIds = const [],
  });

  factory DocumentaryClaim.fromJson(Map<String, dynamic> json) =>
      DocumentaryClaim(
        id: _requiredText(json, 'id'),
        catalogEntryId: _requiredText(json, 'catalogEntryId'),
        number: _requiredText(json, 'number'),
        sourceId: _requiredText(json, 'sourceId'),
        sourceLocation: _requiredText(json, 'sourceLocation'),
        verificationStatus: _enumValue(
          json['verificationStatus'],
          VerificationStatus.values,
          'verificationStatus',
        ),
        notes: _optionalText(json, 'notes'),
        rightsEvidenceIds: _optionalStringList(json, 'rightsEvidenceIds'),
      );
}

class EditorialInterpretation {
  final String id;
  final String catalogEntryId;
  final String text;
  final List<String> sourceReferences;
  final VerificationStatus verificationStatus;
  final PublicationStatus publicationStatus;
  final List<String> rightsEvidenceIds;

  const EditorialInterpretation({
    required this.id,
    required this.catalogEntryId,
    required this.text,
    required this.sourceReferences,
    required this.verificationStatus,
    required this.publicationStatus,
    this.rightsEvidenceIds = const [],
  });

  factory EditorialInterpretation.fromJson(Map<String, dynamic> json) =>
      EditorialInterpretation(
        id: _requiredText(json, 'id'),
        catalogEntryId: _requiredText(json, 'catalogEntryId'),
        text: _requiredText(json, 'text'),
        sourceReferences: _stringList(json, 'sourceReferences'),
        verificationStatus: _enumValue(
          json['verificationStatus'],
          VerificationStatus.values,
          'verificationStatus',
        ),
        publicationStatus: _enumValue(
          json['publicationStatus'],
          PublicationStatus.values,
          'publicationStatus',
        ),
        rightsEvidenceIds: _optionalStringList(json, 'rightsEvidenceIds'),
      );
}

class CulturalArticle {
  final String id;
  final String title;
  final String category;
  final String text;
  final List<String> sourceReferences;
  final List<String> rightsEvidenceIds;
  final VerificationStatus verificationStatus;
  final RightsStatus rightsStatus;
  final PublicationStatus publicationStatus;
  final String reviewedAt;

  const CulturalArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.text,
    required this.sourceReferences,
    required this.rightsEvidenceIds,
    required this.verificationStatus,
    required this.rightsStatus,
    required this.publicationStatus,
    required this.reviewedAt,
  });

  factory CulturalArticle.fromJson(Map<String, dynamic> json) =>
      CulturalArticle(
        id: _requiredText(json, 'id'),
        title: _requiredText(json, 'title'),
        category: _requiredText(json, 'category'),
        text: _requiredText(json, 'text'),
        sourceReferences: _stringList(json, 'sourceReferences'),
        rightsEvidenceIds: _optionalStringList(json, 'rightsEvidenceIds'),
        verificationStatus: _enumValue(
          json['verificationStatus'],
          VerificationStatus.values,
          'verificationStatus',
        ),
        rightsStatus: _enumValue(
          json['rightsStatus'],
          RightsStatus.values,
          'rightsStatus',
        ),
        publicationStatus: _enumValue(
          json['publicationStatus'],
          PublicationStatus.values,
          'publicationStatus',
        ),
        reviewedAt: _requiredText(json, 'reviewedAt'),
      );
}

class ConflictGroup {
  final String id;
  final List<String> claimIds;
  final ConflictType conflictType;
  final String explanation;

  const ConflictGroup({
    required this.id,
    required this.claimIds,
    required this.conflictType,
    required this.explanation,
  });

  factory ConflictGroup.fromJson(Map<String, dynamic> json) => ConflictGroup(
        id: _requiredText(json, 'id'),
        claimIds: _stringList(json, 'claimIds'),
        conflictType: _enumValue(
          json['conflictType'],
          ConflictType.values,
          'conflictType',
        ),
        explanation: _requiredText(json, 'explanation'),
      );
}

class CatalogMetadata {
  final String schemaVersion;
  final String catalogVersion;
  final String locale;
  final String generatedAt;
  final PublicationStatus editorialStatus;

  const CatalogMetadata({
    required this.schemaVersion,
    required this.catalogVersion,
    required this.locale,
    required this.generatedAt,
    required this.editorialStatus,
  });

  factory CatalogMetadata.fromJson(Map<String, dynamic> json) =>
      CatalogMetadata(
        schemaVersion: _requiredText(json, 'schemaVersion'),
        catalogVersion: _requiredText(json, 'catalogVersion'),
        locale: _requiredText(json, 'locale'),
        generatedAt: _requiredText(json, 'generatedAt'),
        editorialStatus: _enumValue(
          json['editorialStatus'],
          PublicationStatus.values,
          'editorialStatus',
        ),
      );
}

class DreamsCatalog {
  final CatalogMetadata metadata;
  final List<Source> sources;
  final List<CatalogEntry> entries;
  final List<DocumentaryClaim> claims;
  final List<EditorialInterpretation> interpretations;
  final List<ConflictGroup> conflictGroups;
  final List<RightsEvidence> rightsEvidence;
  final List<CulturalArticle> articles;

  const DreamsCatalog({
    required this.metadata,
    required this.sources,
    required this.entries,
    required this.claims,
    required this.interpretations,
    required this.conflictGroups,
    this.rightsEvidence = const [],
    this.articles = const [],
  });

  factory DreamsCatalog.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String field, T Function(Map<String, dynamic>) parse) {
      final value = json[field];
      if (value is! List) throw FormatException('$field must be a list.');
      return value
          .map((item) => parse(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    List<T> parseOptionalList<T>(
      String field,
      T Function(Map<String, dynamic>) parse,
    ) {
      if (json[field] == null) return const [];
      return parseList(field, parse);
    }

    final metadata = json['metadata'];
    if (metadata is! Map) {
      throw const FormatException('metadata must be an object.');
    }
    return DreamsCatalog(
      metadata: CatalogMetadata.fromJson(Map<String, dynamic>.from(metadata)),
      sources: parseList('sources', Source.fromJson),
      entries: parseList('entries', CatalogEntry.fromJson),
      claims: parseList('claims', DocumentaryClaim.fromJson),
      interpretations:
          parseList('interpretations', EditorialInterpretation.fromJson),
      conflictGroups: parseList('conflictGroups', ConflictGroup.fromJson),
      rightsEvidence:
          parseOptionalList('rightsEvidence', RightsEvidence.fromJson),
      articles: parseOptionalList('articles', CulturalArticle.fromJson),
    );
  }

  Source sourceById(String id) => sources.firstWhere((item) => item.id == id);

  CatalogEntry entryById(String id) =>
      entries.firstWhere((item) => item.id == id);

  List<DocumentaryClaim> claimsFor(String entryId) =>
      claims.where((item) => item.catalogEntryId == entryId).toList();

  List<ConflictGroup> conflictsForClaims(Iterable<String> claimIds) {
    final ids = claimIds.toSet();
    return conflictGroups
        .where((group) => group.claimIds.any(ids.contains))
        .toList();
  }
}
