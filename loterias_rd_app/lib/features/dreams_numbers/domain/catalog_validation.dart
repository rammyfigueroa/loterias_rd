import 'dreams_catalog.dart';

class CatalogValidationIssue {
  final String path;
  final String message;

  const CatalogValidationIssue(this.path, this.message);

  @override
  String toString() => '$path: $message';
}

class CatalogValidationException implements Exception {
  final List<CatalogValidationIssue> issues;

  const CatalogValidationException(this.issues);

  @override
  String toString() =>
      'Catalog validation failed:\n${issues.map((item) => '- $item').join('\n')}';
}

class PublicationContext {
  final DateTime referenceDate;
  final bool worldwideDistribution;
  final Set<String> distributionTerritories;
  final Set<String> incompatibleRestrictions;
  final bool requiresDerivativeWorks;

  const PublicationContext({
    required this.referenceDate,
    this.worldwideDistribution = true,
    this.distributionTerritories = const {},
    this.incompatibleRestrictions = const {},
    this.requiresDerivativeWorks = true,
  });
}

class CatalogValidator {
  static const supportedSchemaVersions = {'1.0.0', '1.1.0', '1.2.0'};
  static final _idPattern = RegExp(r'^[a-z][a-z0-9_-]*$');
  static final _numberPattern = RegExp(r'^(?:0[0-9]|[1-9][0-9])$');
  static final _datePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _dateTimePattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
  );

  const CatalogValidator();

  List<CatalogValidationIssue> validate(DreamsCatalog catalog) {
    final issues = <CatalogValidationIssue>[];
    if (!supportedSchemaVersions.contains(catalog.metadata.schemaVersion)) {
      issues.add(CatalogValidationIssue(
        'metadata.schemaVersion',
        'Unsupported schema version ${catalog.metadata.schemaVersion}; '
            'expected one of ${supportedSchemaVersions.join(', ')}.',
      ));
    }
    if (catalog.metadata.locale.trim().isEmpty) {
      issues.add(const CatalogValidationIssue(
          'metadata.locale', 'Locale is required.'));
    }
    if (!_isDateTime(catalog.metadata.generatedAt)) {
      issues.add(const CatalogValidationIssue(
          'metadata.generatedAt', 'Must be an ISO-8601 date-time.'));
    }

    _validateIds('sources', catalog.sources.map((item) => item.id), issues);
    _validateIds('entries', catalog.entries.map((item) => item.id), issues);
    _validateIds('claims', catalog.claims.map((item) => item.id), issues);
    _validateIds(
      'interpretations',
      catalog.interpretations.map((item) => item.id),
      issues,
    );
    _validateIds(
      'conflictGroups',
      catalog.conflictGroups.map((item) => item.id),
      issues,
    );
    _validateIds(
      'rightsEvidence',
      catalog.rightsEvidence.map((item) => item.id),
      issues,
    );
    _validateIds('articles', catalog.articles.map((item) => item.id), issues);

    final sourceIds = catalog.sources.map((item) => item.id).toSet();
    final entryIds = catalog.entries.map((item) => item.id).toSet();
    final claimIds = catalog.claims.map((item) => item.id).toSet();
    final evidenceIds = catalog.rightsEvidence.map((item) => item.id).toSet();

    for (var i = 0; i < catalog.sources.length; i++) {
      final source = catalog.sources[i];
      if (!_isDate(source.accessDate)) {
        issues.add(CatalogValidationIssue(
          'sources[$i].accessDate',
          'Must be an ISO-8601 date.',
        ));
      }
      if (source.publicationDate != null && !_isDate(source.publicationDate!)) {
        issues.add(CatalogValidationIssue(
          'sources[$i].publicationDate',
          'Must be an ISO-8601 date when provided.',
        ));
      }
    }

    for (var i = 0; i < catalog.entries.length; i++) {
      final seenVariants = <String>{};
      for (var j = 0; j < catalog.entries[i].variants.length; j++) {
        final normalized =
            catalog.entries[i].variants[j].term.trim().toLowerCase();
        if (!seenVariants.add(normalized)) {
          issues.add(CatalogValidationIssue(
            'entries[$i].variants[$j]',
            'Duplicate variant in the same entry.',
          ));
        }
      }
    }

    for (var i = 0; i < catalog.claims.length; i++) {
      final claim = catalog.claims[i];
      if (!entryIds.contains(claim.catalogEntryId)) {
        issues.add(CatalogValidationIssue(
          'claims[$i].catalogEntryId',
          'Unknown entry ${claim.catalogEntryId}.',
        ));
      }
      if (!sourceIds.contains(claim.sourceId)) {
        issues.add(CatalogValidationIssue(
          'claims[$i].sourceId',
          'Unknown source ${claim.sourceId}.',
        ));
      }
      if (!_numberPattern.hasMatch(claim.number)) {
        issues.add(CatalogValidationIssue(
          'claims[$i].number',
          'Number must be a two-digit string from 00 to 99.',
        ));
      }
      _validateEvidenceReferences(
        'claims[$i].rightsEvidenceIds',
        claim.rightsEvidenceIds,
        evidenceIds,
        issues,
      );
    }

    for (var i = 0; i < catalog.interpretations.length; i++) {
      final interpretation = catalog.interpretations[i];
      if (!entryIds.contains(interpretation.catalogEntryId)) {
        issues.add(CatalogValidationIssue(
          'interpretations[$i].catalogEntryId',
          'Unknown entry ${interpretation.catalogEntryId}.',
        ));
      }
      for (final sourceId in interpretation.sourceReferences) {
        if (!sourceIds.contains(sourceId)) {
          issues.add(CatalogValidationIssue(
            'interpretations[$i].sourceReferences',
            'Unknown source $sourceId.',
          ));
        }
      }
      if (interpretation.sourceReferences.toSet().length !=
          interpretation.sourceReferences.length) {
        issues.add(CatalogValidationIssue(
          'interpretations[$i].sourceReferences',
          'Source references cannot contain duplicates.',
        ));
      }
      _validateEvidenceReferences(
        'interpretations[$i].rightsEvidenceIds',
        interpretation.rightsEvidenceIds,
        evidenceIds,
        issues,
      );
    }

    for (var i = 0; i < catalog.rightsEvidence.length; i++) {
      final evidence = catalog.rightsEvidence[i];
      if (!sourceIds.contains(evidence.sourceId)) {
        issues.add(CatalogValidationIssue(
          'rightsEvidence[$i].sourceId',
          'Unknown source ${evidence.sourceId}.',
        ));
      }
      for (final field in {
        'evidenceDate': evidence.evidenceDate,
        'validFrom': evidence.validFrom,
        'reviewedAt': evidence.reviewedAt,
      }.entries) {
        if (!_isDate(field.value)) {
          issues.add(CatalogValidationIssue(
            'rightsEvidence[$i].${field.key}',
            'Must be an ISO-8601 date.',
          ));
        }
      }
      if (evidence.validUntil != null && !_isDate(evidence.validUntil!)) {
        issues.add(CatalogValidationIssue(
          'rightsEvidence[$i].validUntil',
          'Must be an ISO-8601 date when provided.',
        ));
      }
      if (evidence.legalConclusionDate != null &&
          !_isDate(evidence.legalConclusionDate!)) {
        issues.add(CatalogValidationIssue(
          'rightsEvidence[$i].legalConclusionDate',
          'Must be an ISO-8601 date when provided.',
        ));
      }
      _validateSourceReferences(
        'rightsEvidence[$i].historicalFactReferences',
        evidence.historicalFactReferences,
        sourceIds,
        issues,
        allowEmpty: true,
      );
      if (evidence.scopeReferences.isEmpty) {
        issues.add(CatalogValidationIssue(
          'rightsEvidence[$i].scopeReferences',
          'At least one verifiable scope reference is required.',
        ));
      }
      if (evidence.territory == TerritoryScope.specificTerritories &&
          evidence.territories.isEmpty) {
        issues.add(CatalogValidationIssue(
          'rightsEvidence[$i].territories',
          'Specific territory authorization requires territory codes.',
        ));
      }
    }

    for (var i = 0; i < catalog.articles.length; i++) {
      final article = catalog.articles[i];
      if (!_isDate(article.reviewedAt)) {
        issues.add(CatalogValidationIssue(
          'articles[$i].reviewedAt',
          'Must be an ISO-8601 date.',
        ));
      }
      _validateSourceReferences(
        'articles[$i].sourceReferences',
        article.sourceReferences,
        sourceIds,
        issues,
      );
      _validateEvidenceReferences(
        'articles[$i].rightsEvidenceIds',
        article.rightsEvidenceIds,
        evidenceIds,
        issues,
      );
    }

    for (var i = 0; i < catalog.conflictGroups.length; i++) {
      final group = catalog.conflictGroups[i];
      if (group.claimIds.length < 2) {
        issues.add(CatalogValidationIssue(
          'conflictGroups[$i].claimIds',
          'A conflict must contain at least two claims.',
        ));
      }
      if (group.claimIds.toSet().length != group.claimIds.length) {
        issues.add(CatalogValidationIssue(
          'conflictGroups[$i].claimIds',
          'A conflict cannot repeat a claim.',
        ));
      }
      for (final claimId in group.claimIds) {
        if (!claimIds.contains(claimId)) {
          issues.add(CatalogValidationIssue(
            'conflictGroups[$i].claimIds',
            'Unknown claim $claimId.',
          ));
        }
      }
    }
    return issues;
  }

  List<CatalogValidationIssue> validateForPublication(
    DreamsCatalog catalog,
    PublicationContext context,
  ) {
    final issues = validate(catalog);
    if (catalog.metadata.editorialStatus != PublicationStatus.approved) {
      issues.add(const CatalogValidationIssue(
        'metadata.editorialStatus',
        'Catalog is not approved for publication.',
      ));
    }
    final sources = {for (final source in catalog.sources) source.id: source};
    final evidenceById = {
      for (final evidence in catalog.rightsEvidence) evidence.id: evidence,
    };
    if (catalog.metadata.schemaVersion != '1.2.0') {
      issues.add(const CatalogValidationIssue(
        'metadata.schemaVersion',
        'Publication with legal-basis evidence requires schema version 1.2.0.',
      ));
    }
    final originalEvidenceIds = catalog.articles
        .expand((article) => article.rightsEvidenceIds)
        .where((id) =>
            evidenceById[id]?.legalBasisType == LegalBasisType.originalWork)
        .toSet();
    final factualSourceIds = originalEvidenceIds
        .map((id) => evidenceById[id])
        .whereType<RightsEvidence>()
        .expand((evidence) => evidence.historicalFactReferences)
        .toSet();
    final thirdPartySourceIds = <String>{
      ...catalog.claims.map((claim) => claim.sourceId),
      ...catalog.interpretations
          .expand((interpretation) => interpretation.sourceReferences),
      ...catalog.articles
          .where((article) =>
              !article.rightsEvidenceIds.any(originalEvidenceIds.contains))
          .expand((article) => article.sourceReferences),
    };
    for (var i = 0; i < catalog.sources.length; i++) {
      final source = catalog.sources[i];
      final requiresThirdPartyAuthorization =
          thirdPartySourceIds.contains(source.id);
      if (requiresThirdPartyAuthorization &&
          source.rightsStatus != RightsStatus.authorized) {
        issues.add(CatalogValidationIssue(
          'sources[$i].rightsStatus',
          'Source ${source.id} does not have explicit publication authorization.',
        ));
      }
      if (source.verificationStatus != VerificationStatus.verified) {
        issues.add(CatalogValidationIssue(
          'sources[$i].verificationStatus',
          'Source ${source.id} is not verified for publication.',
        ));
      }
      if (requiresThirdPartyAuthorization &&
          !catalog.rightsEvidence.any((item) =>
              item.sourceId == source.id &&
              item.legalBasisType != LegalBasisType.originalWork)) {
        issues.add(CatalogValidationIssue(
          'sources[$i].rightsStatus',
          'Source ${source.id} is authorized but has no rights evidence.',
        ));
      }
      if (factualSourceIds.contains(source.id) &&
          const {
            RightsStatus.unknown,
            RightsStatus.unauthorized,
            RightsStatus.restricted,
          }.contains(source.rightsStatus)) {
        issues.add(CatalogValidationIssue(
          'sources[$i].rightsStatus',
          'Factual source ${source.id} has an unacceptable rights status.',
        ));
      }
    }
    for (var i = 0; i < catalog.rightsEvidence.length; i++) {
      _validatePublishableEvidence(
        catalog.rightsEvidence[i],
        i,
        context,
        issues,
      );
    }
    for (var i = 0; i < catalog.claims.length; i++) {
      final claim = catalog.claims[i];
      final source = sources[claim.sourceId];
      if (source == null) continue;
      if (claim.verificationStatus != VerificationStatus.verified) {
        issues.add(CatalogValidationIssue(
          'claims[$i].verificationStatus',
          'Claim ${claim.id} is not verified for publication.',
        ));
      }
      _validateContentEvidence(
        path: 'claims[$i]',
        contentId: claim.id,
        sourceIds: {claim.sourceId},
        evidenceIds: claim.rightsEvidenceIds,
        allowedScopes: const {
          RightsScopeType.fullSource,
          RightsScopeType.specificFragment,
          RightsScopeType.table,
          RightsScopeType.structuredData,
        },
        evidenceById: evidenceById,
        issues: issues,
      );
    }
    for (var i = 0; i < catalog.interpretations.length; i++) {
      final interpretation = catalog.interpretations[i];
      if (interpretation.publicationStatus != PublicationStatus.approved) {
        issues.add(CatalogValidationIssue(
          'interpretations[$i].publicationStatus',
          'Interpretation is not approved for publication.',
        ));
      }
      if (interpretation.verificationStatus != VerificationStatus.verified) {
        issues.add(CatalogValidationIssue(
          'interpretations[$i].verificationStatus',
          'Interpretation ${interpretation.id} is not verified for publication.',
        ));
      }
      if (interpretation.sourceReferences.isEmpty) {
        issues.add(CatalogValidationIssue(
          'interpretations[$i].sourceReferences',
          'A publishable interpretation must reference at least one source.',
        ));
      }
      _validateContentEvidence(
        path: 'interpretations[$i]',
        contentId: interpretation.id,
        sourceIds: interpretation.sourceReferences.toSet(),
        evidenceIds: interpretation.rightsEvidenceIds,
        allowedScopes: const {
          RightsScopeType.fullSource,
          RightsScopeType.specificFragment,
          RightsScopeType.editorialText,
        },
        evidenceById: evidenceById,
        issues: issues,
        allowOriginalWork: true,
      );
    }
    for (var i = 0; i < catalog.articles.length; i++) {
      final article = catalog.articles[i];
      if (article.publicationStatus != PublicationStatus.approved ||
          article.verificationStatus != VerificationStatus.verified ||
          article.rightsStatus != RightsStatus.authorized) {
        issues.add(CatalogValidationIssue(
          'articles[$i]',
          'Article ${article.id} is not approved, verified, and authorized.',
        ));
      }
      _validateContentEvidence(
        path: 'articles[$i]',
        contentId: article.id,
        sourceIds: article.sourceReferences.toSet(),
        evidenceIds: article.rightsEvidenceIds,
        allowedScopes: const {
          RightsScopeType.fullSource,
          RightsScopeType.specificFragment,
          RightsScopeType.article,
        },
        evidenceById: evidenceById,
        issues: issues,
        allowOriginalWork: true,
      );
    }
    return issues;
  }

  void requireValid(DreamsCatalog catalog) {
    final issues = validate(catalog);
    if (issues.isNotEmpty) throw CatalogValidationException(issues);
  }

  void requirePublishable(DreamsCatalog catalog, PublicationContext context) {
    final issues = validateForPublication(catalog, context);
    if (issues.isNotEmpty) throw CatalogValidationException(issues);
  }

  void _validatePublishableEvidence(
    RightsEvidence evidence,
    int index,
    PublicationContext context,
    List<CatalogValidationIssue> issues,
  ) {
    final path = 'rightsEvidence[$index]';
    final reference = DateTime.utc(
      context.referenceDate.year,
      context.referenceDate.month,
      context.referenceDate.day,
    );
    DateTime? date(String value) =>
        _isDate(value) ? DateTime.parse(value) : null;
    final evidenceDate = date(evidence.evidenceDate);
    final validFrom = date(evidence.validFrom);
    final validUntil =
        evidence.validUntil == null ? null : date(evidence.validUntil!);
    final reviewedAt = date(evidence.reviewedAt);
    final legalConclusionDate = evidence.legalConclusionDate == null
        ? null
        : date(evidence.legalConclusionDate!);
    if (evidence.rightsHolder.trim().isEmpty ||
        evidence.evidenceReference.trim().isEmpty) {
      issues.add(CatalogValidationIssue(
          path, 'Rights holder and evidence reference are required.'));
    }
    if (evidence.reviewStatus != RightsReviewStatus.approved) {
      issues.add(CatalogValidationIssue(
          '$path.reviewStatus', 'Rights evidence is not approved.'));
    }
    if (evidenceDate != null && evidenceDate.isAfter(reference) ||
        reviewedAt != null && reviewedAt.isAfter(reference) ||
        validFrom != null && validFrom.isAfter(reference) ||
        legalConclusionDate != null && legalConclusionDate.isAfter(reference)) {
      issues.add(CatalogValidationIssue(
          path, 'Rights evidence is future-dated or not yet valid.'));
    }
    if (validUntil != null && validUntil.isBefore(reference)) {
      issues.add(CatalogValidationIssue(
          '$path.validUntil', 'Rights evidence has expired.'));
    }
    if (validUntil == null &&
        (evidence.indefiniteTermJustification == null ||
            evidence.indefiniteTermJustification!.trim().isEmpty)) {
      issues.add(CatalogValidationIssue('$path.validUntil',
          'Indefinite authorization requires a justification.'));
    }
    if (!evidence.commercialUseAllowed) {
      issues.add(CatalogValidationIssue(
          '$path.commercialUseAllowed', 'Commercial use is not allowed.'));
    }
    if (!evidence.redistributionAllowed) {
      issues.add(CatalogValidationIssue(
          '$path.redistributionAllowed', 'Redistribution is not allowed.'));
    }
    if (context.requiresDerivativeWorks && !evidence.derivativeWorksAllowed) {
      issues.add(CatalogValidationIssue('$path.derivativeWorksAllowed',
          'Derivative works required by the publication context are not allowed.'));
    }
    if (context.worldwideDistribution &&
        evidence.territory != TerritoryScope.worldwide) {
      issues.add(CatalogValidationIssue('$path.territory',
          'Territory does not cover worldwide distribution.'));
    } else if (!context.worldwideDistribution &&
        evidence.territory == TerritoryScope.dominicanRepublic &&
        context.distributionTerritories.any((item) => item != 'DO')) {
      issues.add(CatalogValidationIssue('$path.territory',
          'Territory does not cover the intended distribution.'));
    } else if (!context.worldwideDistribution &&
        evidence.territory == TerritoryScope.specificTerritories &&
        !evidence.territories
            .toSet()
            .containsAll(context.distributionTerritories)) {
      issues.add(CatalogValidationIssue('$path.territories',
          'Specific territories do not cover the intended distribution.'));
    }
    final conflicts = evidence.restrictions
        .toSet()
        .intersection(context.incompatibleRestrictions);
    if (conflicts.isNotEmpty) {
      issues.add(CatalogValidationIssue('$path.restrictions',
          'Incompatible restrictions: ${conflicts.join(', ')}.'));
    }
    _validateLegalBasis(evidence, path, issues);
  }

  void _validateLegalBasis(
    RightsEvidence evidence,
    String path,
    List<CatalogValidationIssue> issues,
  ) {
    bool missing(String? value) => value == null || value.trim().isEmpty;
    switch (evidence.legalBasisType) {
      case LegalBasisType.explicitPermission:
        if (!const {
          AuthorizationType.writtenPermission,
          AuthorizationType.contract,
        }.contains(evidence.authorizationType)) {
          issues.add(CatalogValidationIssue('$path.authorizationType',
              'Explicit permission requires a written permission or contract.'));
        }
        break;
      case LegalBasisType.originalWork:
        if (missing(evidence.authorshipReference) ||
            missing(evidence.originalityDeclaration) ||
            missing(evidence.editorialReviewReference) ||
            evidence.historicalFactReferences.isEmpty ||
            evidence.unauthorizedReproductionConfirmedAbsent != true) {
          issues.add(CatalogValidationIssue(path,
              'Original work requires authorship, originality, editorial review, factual references, and confirmation of no unauthorized reproduction.'));
        }
        if (evidence.scopeType != RightsScopeType.article &&
            evidence.scopeType != RightsScopeType.editorialText) {
          issues.add(CatalogValidationIssue('$path.scopeType',
              'Original work can cover only an article or editorial text.'));
        }
        break;
      case LegalBasisType.compatibleOpenLicense:
        if (evidence.authorizationType != AuthorizationType.openLicense ||
            missing(evidence.licenseIdentifier) ||
            missing(evidence.licenseVersion) ||
            missing(evidence.licenseUrl) ||
            evidence.licenseConditions.isEmpty ||
            missing(evidence.attributionReference)) {
          issues.add(CatalogValidationIssue(path,
              'Compatible open license requires an identified license, version, URL, conditions, and attribution.'));
        }
        break;
      case LegalBasisType.reviewedLegalException:
        if (missing(evidence.legalJurisdiction) ||
            missing(evidence.legalException) ||
            missing(evidence.legalReviewReference) ||
            missing(evidence.legalReviewerRole) ||
            missing(evidence.legalConclusionDate) ||
            evidence.legalLimitations.isEmpty) {
          issues.add(CatalogValidationIssue(path,
              'Reviewed legal exception requires jurisdiction, exception, documented review, reviewer role, conclusion date, and limitations.'));
        }
        break;
      case null:
        issues.add(CatalogValidationIssue('$path.legalBasisType',
            'A legal basis is required for publication.'));
        break;
    }
  }

  void _validateContentEvidence({
    required String path,
    required String contentId,
    required Set<String> sourceIds,
    required List<String> evidenceIds,
    required Set<RightsScopeType> allowedScopes,
    required Map<String, RightsEvidence> evidenceById,
    required List<CatalogValidationIssue> issues,
    bool allowOriginalWork = false,
  }) {
    for (final sourceId in sourceIds) {
      final matching = evidenceIds
          .map((id) => evidenceById[id])
          .whereType<RightsEvidence>()
          .where((evidence) {
        final scopeMatches = allowedScopes.contains(evidence.scopeType) &&
            evidence.scopeReferences.contains(
              evidence.scopeType == RightsScopeType.fullSource
                  ? sourceId
                  : contentId,
            );
        if (!scopeMatches) return false;
        if (allowOriginalWork &&
            evidence.legalBasisType == LegalBasisType.originalWork) {
          return evidence.historicalFactReferences.contains(sourceId);
        }
        return evidence.sourceId == sourceId;
      }).toList();
      if (matching.isEmpty) {
        issues.add(CatalogValidationIssue(
          '$path.rightsEvidenceIds',
          'No rights evidence covers $contentId from source $sourceId with the required scope.',
        ));
      }
    }
  }

  void _validateEvidenceReferences(
    String path,
    List<String> ids,
    Set<String> knownIds,
    List<CatalogValidationIssue> issues,
  ) {
    if (ids.toSet().length != ids.length) {
      issues.add(CatalogValidationIssue(
          path, 'Rights evidence references cannot contain duplicates.'));
    }
    for (final id in ids) {
      if (!knownIds.contains(id)) {
        issues
            .add(CatalogValidationIssue(path, 'Unknown rights evidence $id.'));
      }
    }
  }

  void _validateSourceReferences(
    String path,
    List<String> ids,
    Set<String> knownIds,
    List<CatalogValidationIssue> issues, {
    bool allowEmpty = false,
  }) {
    if (!allowEmpty && ids.isEmpty)
      issues.add(
          CatalogValidationIssue(path, 'At least one source is required.'));
    if (ids.toSet().length != ids.length)
      issues.add(CatalogValidationIssue(
          path, 'Source references cannot contain duplicates.'));
    for (final id in ids) {
      if (!knownIds.contains(id))
        issues.add(CatalogValidationIssue(path, 'Unknown source $id.'));
    }
  }

  void _validateIds(
    String path,
    Iterable<String> ids,
    List<CatalogValidationIssue> issues,
  ) {
    final seen = <String>{};
    var index = 0;
    for (final id in ids) {
      if (!_idPattern.hasMatch(id)) {
        issues.add(CatalogValidationIssue(
          '$path[$index].id',
          'ID must match ${_idPattern.pattern}.',
        ));
      }
      if (!seen.add(id)) {
        issues.add(CatalogValidationIssue(
          '$path[$index].id',
          'Duplicate ID $id.',
        ));
      }
      index++;
    }
  }

  bool _isDate(String value) {
    if (!_datePattern.hasMatch(value)) return false;
    final parsed = DateTime.tryParse(value);
    return parsed != null &&
        parsed.year.toString().padLeft(4, '0') == value.substring(0, 4) &&
        parsed.month.toString().padLeft(2, '0') == value.substring(5, 7) &&
        parsed.day.toString().padLeft(2, '0') == value.substring(8, 10);
  }

  bool _isDateTime(String value) =>
      _dateTimePattern.hasMatch(value) && DateTime.tryParse(value) != null;
}
