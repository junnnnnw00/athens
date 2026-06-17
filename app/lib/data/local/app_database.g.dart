// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LocalItemsTable extends LocalItems
    with TableInfo<$LocalItemsTable, LocalItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
      'kind', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
      'source', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _primaryArtistMeta =
      const VerificationMeta('primaryArtist');
  @override
  late final GeneratedColumn<String> primaryArtist = GeneratedColumn<String>(
      'primary_artist', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imageUrlMeta =
      const VerificationMeta('imageUrl');
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
      'image_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _canonicalKeyMeta =
      const VerificationMeta('canonicalKey');
  @override
  late final GeneratedColumn<String> canonicalKey = GeneratedColumn<String>(
      'canonical_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>('created_at', aliasedName, false,
              type: DriftSqlType.dateTime,
              requiredDuringInsert: false,
              defaultValue: currentDateAndTime)
          .withConverter<DateTime>($LocalItemsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        kind,
        source,
        sourceId,
        title,
        primaryArtist,
        imageUrl,
        tags,
        canonicalKey,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_items';
  @override
  VerificationContext validateIntegrity(Insertable<LocalItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
          _kindMeta, kind.isAcceptableOrUnknown(data['kind']!, _kindMeta));
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta,
          source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('primary_artist')) {
      context.handle(
          _primaryArtistMeta,
          primaryArtist.isAcceptableOrUnknown(
              data['primary_artist']!, _primaryArtistMeta));
    }
    if (data.containsKey('image_url')) {
      context.handle(_imageUrlMeta,
          imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('canonical_key')) {
      context.handle(
          _canonicalKeyMeta,
          canonicalKey.isAcceptableOrUnknown(
              data['canonical_key']!, _canonicalKeyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      kind: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      source: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      primaryArtist: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}primary_artist']),
      imageUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_url']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      canonicalKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}canonical_key']),
      createdAt: $LocalItemsTable.$convertercreatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  $LocalItemsTable createAlias(String alias) {
    return $LocalItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const DateTimeCorrectionConverter();
}

class LocalItem extends DataClass implements Insertable<LocalItem> {
  final String id;
  final String kind;
  final String source;
  final String sourceId;
  final String title;
  final String? primaryArtist;
  final String? imageUrl;
  final String tags;

  /// Cross-source dedup identity (ISRC-based for tracks). Null until resolved.
  /// See `catalogCanonicalKey`.
  final String? canonicalKey;
  final DateTime createdAt;
  const LocalItem(
      {required this.id,
      required this.kind,
      required this.source,
      required this.sourceId,
      required this.title,
      this.primaryArtist,
      this.imageUrl,
      required this.tags,
      this.canonicalKey,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['source'] = Variable<String>(source);
    map['source_id'] = Variable<String>(sourceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || primaryArtist != null) {
      map['primary_artist'] = Variable<String>(primaryArtist);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['tags'] = Variable<String>(tags);
    if (!nullToAbsent || canonicalKey != null) {
      map['canonical_key'] = Variable<String>(canonicalKey);
    }
    {
      map['created_at'] = Variable<DateTime>(
          $LocalItemsTable.$convertercreatedAt.toSql(createdAt));
    }
    return map;
  }

  LocalItemsCompanion toCompanion(bool nullToAbsent) {
    return LocalItemsCompanion(
      id: Value(id),
      kind: Value(kind),
      source: Value(source),
      sourceId: Value(sourceId),
      title: Value(title),
      primaryArtist: primaryArtist == null && nullToAbsent
          ? const Value.absent()
          : Value(primaryArtist),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      tags: Value(tags),
      canonicalKey: canonicalKey == null && nullToAbsent
          ? const Value.absent()
          : Value(canonicalKey),
      createdAt: Value(createdAt),
    );
  }

  factory LocalItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalItem(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      source: serializer.fromJson<String>(json['source']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      title: serializer.fromJson<String>(json['title']),
      primaryArtist: serializer.fromJson<String?>(json['primaryArtist']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      tags: serializer.fromJson<String>(json['tags']),
      canonicalKey: serializer.fromJson<String?>(json['canonicalKey']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'source': serializer.toJson<String>(source),
      'sourceId': serializer.toJson<String>(sourceId),
      'title': serializer.toJson<String>(title),
      'primaryArtist': serializer.toJson<String?>(primaryArtist),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'tags': serializer.toJson<String>(tags),
      'canonicalKey': serializer.toJson<String?>(canonicalKey),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalItem copyWith(
          {String? id,
          String? kind,
          String? source,
          String? sourceId,
          String? title,
          Value<String?> primaryArtist = const Value.absent(),
          Value<String?> imageUrl = const Value.absent(),
          String? tags,
          Value<String?> canonicalKey = const Value.absent(),
          DateTime? createdAt}) =>
      LocalItem(
        id: id ?? this.id,
        kind: kind ?? this.kind,
        source: source ?? this.source,
        sourceId: sourceId ?? this.sourceId,
        title: title ?? this.title,
        primaryArtist:
            primaryArtist.present ? primaryArtist.value : this.primaryArtist,
        imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
        tags: tags ?? this.tags,
        canonicalKey:
            canonicalKey.present ? canonicalKey.value : this.canonicalKey,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalItem copyWithCompanion(LocalItemsCompanion data) {
    return LocalItem(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      source: data.source.present ? data.source.value : this.source,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      title: data.title.present ? data.title.value : this.title,
      primaryArtist: data.primaryArtist.present
          ? data.primaryArtist.value
          : this.primaryArtist,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      tags: data.tags.present ? data.tags.value : this.tags,
      canonicalKey: data.canonicalKey.present
          ? data.canonicalKey.value
          : this.canonicalKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalItem(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('primaryArtist: $primaryArtist, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('tags: $tags, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, source, sourceId, title,
      primaryArtist, imageUrl, tags, canonicalKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalItem &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.source == this.source &&
          other.sourceId == this.sourceId &&
          other.title == this.title &&
          other.primaryArtist == this.primaryArtist &&
          other.imageUrl == this.imageUrl &&
          other.tags == this.tags &&
          other.canonicalKey == this.canonicalKey &&
          other.createdAt == this.createdAt);
}

class LocalItemsCompanion extends UpdateCompanion<LocalItem> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> source;
  final Value<String> sourceId;
  final Value<String> title;
  final Value<String?> primaryArtist;
  final Value<String?> imageUrl;
  final Value<String> tags;
  final Value<String?> canonicalKey;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalItemsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.title = const Value.absent(),
    this.primaryArtist = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.tags = const Value.absent(),
    this.canonicalKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalItemsCompanion.insert({
    required String id,
    required String kind,
    required String source,
    required String sourceId,
    required String title,
    this.primaryArtist = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.tags = const Value.absent(),
    this.canonicalKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        kind = Value(kind),
        source = Value(source),
        sourceId = Value(sourceId),
        title = Value(title);
  static Insertable<LocalItem> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? source,
    Expression<String>? sourceId,
    Expression<String>? title,
    Expression<String>? primaryArtist,
    Expression<String>? imageUrl,
    Expression<String>? tags,
    Expression<String>? canonicalKey,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (source != null) 'source': source,
      if (sourceId != null) 'source_id': sourceId,
      if (title != null) 'title': title,
      if (primaryArtist != null) 'primary_artist': primaryArtist,
      if (imageUrl != null) 'image_url': imageUrl,
      if (tags != null) 'tags': tags,
      if (canonicalKey != null) 'canonical_key': canonicalKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? kind,
      Value<String>? source,
      Value<String>? sourceId,
      Value<String>? title,
      Value<String?>? primaryArtist,
      Value<String?>? imageUrl,
      Value<String>? tags,
      Value<String?>? canonicalKey,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalItemsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      title: title ?? this.title,
      primaryArtist: primaryArtist ?? this.primaryArtist,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (primaryArtist.present) {
      map['primary_artist'] = Variable<String>(primaryArtist.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (canonicalKey.present) {
      map['canonical_key'] = Variable<String>(canonicalKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
          $LocalItemsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('source: $source, ')
          ..write('sourceId: $sourceId, ')
          ..write('title: $title, ')
          ..write('primaryArtist: $primaryArtist, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('tags: $tags, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRatingsTable extends LocalRatings
    with TableInfo<$LocalRatingsTable, LocalRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _eloMeta = const VerificationMeta('elo');
  @override
  late final GeneratedColumn<double> elo = GeneratedColumn<double>(
      'elo', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1000.0));
  static const VerificationMeta _comparisonsMeta =
      const VerificationMeta('comparisons');
  @override
  late final GeneratedColumn<int> comparisons = GeneratedColumn<int>(
      'comparisons', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>('updated_at', aliasedName, false,
              type: DriftSqlType.dateTime,
              requiredDuringInsert: false,
              defaultValue: currentDateAndTime)
          .withConverter<DateTime>($LocalRatingsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, itemId, elo, comparisons, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_ratings';
  @override
  VerificationContext validateIntegrity(Insertable<LocalRating> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('elo')) {
      context.handle(
          _eloMeta, elo.isAcceptableOrUnknown(data['elo']!, _eloMeta));
    }
    if (data.containsKey('comparisons')) {
      context.handle(
          _comparisonsMeta,
          comparisons.isAcceptableOrUnknown(
              data['comparisons']!, _comparisonsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalRating(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      elo: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}elo'])!,
      comparisons: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}comparisons'])!,
      updatedAt: $LocalRatingsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $LocalRatingsTable createAlias(String alias) {
    return $LocalRatingsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const DateTimeCorrectionConverter();
}

class LocalRating extends DataClass implements Insertable<LocalRating> {
  final String id;
  final String userId;
  final String itemId;
  final double elo;
  final int comparisons;
  final DateTime updatedAt;
  const LocalRating(
      {required this.id,
      required this.userId,
      required this.itemId,
      required this.elo,
      required this.comparisons,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['item_id'] = Variable<String>(itemId);
    map['elo'] = Variable<double>(elo);
    map['comparisons'] = Variable<int>(comparisons);
    {
      map['updated_at'] = Variable<DateTime>(
          $LocalRatingsTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  LocalRatingsCompanion toCompanion(bool nullToAbsent) {
    return LocalRatingsCompanion(
      id: Value(id),
      userId: Value(userId),
      itemId: Value(itemId),
      elo: Value(elo),
      comparisons: Value(comparisons),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalRating.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalRating(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      elo: serializer.fromJson<double>(json['elo']),
      comparisons: serializer.fromJson<int>(json['comparisons']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'itemId': serializer.toJson<String>(itemId),
      'elo': serializer.toJson<double>(elo),
      'comparisons': serializer.toJson<int>(comparisons),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalRating copyWith(
          {String? id,
          String? userId,
          String? itemId,
          double? elo,
          int? comparisons,
          DateTime? updatedAt}) =>
      LocalRating(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        itemId: itemId ?? this.itemId,
        elo: elo ?? this.elo,
        comparisons: comparisons ?? this.comparisons,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalRating copyWithCompanion(LocalRatingsCompanion data) {
    return LocalRating(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      elo: data.elo.present ? data.elo.value : this.elo,
      comparisons:
          data.comparisons.present ? data.comparisons.value : this.comparisons,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalRating(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('elo: $elo, ')
          ..write('comparisons: $comparisons, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, itemId, elo, comparisons, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalRating &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.elo == this.elo &&
          other.comparisons == this.comparisons &&
          other.updatedAt == this.updatedAt);
}

class LocalRatingsCompanion extends UpdateCompanion<LocalRating> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> itemId;
  final Value<double> elo;
  final Value<int> comparisons;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalRatingsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.elo = const Value.absent(),
    this.comparisons = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRatingsCompanion.insert({
    required String id,
    required String userId,
    required String itemId,
    this.elo = const Value.absent(),
    this.comparisons = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        itemId = Value(itemId);
  static Insertable<LocalRating> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? itemId,
    Expression<double>? elo,
    Expression<int>? comparisons,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (elo != null) 'elo': elo,
      if (comparisons != null) 'comparisons': comparisons,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRatingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? itemId,
      Value<double>? elo,
      Value<int>? comparisons,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalRatingsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      elo: elo ?? this.elo,
      comparisons: comparisons ?? this.comparisons,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (elo.present) {
      map['elo'] = Variable<double>(elo.value);
    }
    if (comparisons.present) {
      map['comparisons'] = Variable<int>(comparisons.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
          $LocalRatingsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRatingsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('elo: $elo, ')
          ..write('comparisons: $comparisons, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalComparisonsTable extends LocalComparisons
    with TableInfo<$LocalComparisonsTable, LocalComparison> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalComparisonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _winnerItemIdMeta =
      const VerificationMeta('winnerItemId');
  @override
  late final GeneratedColumn<String> winnerItemId = GeneratedColumn<String>(
      'winner_item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _loserItemIdMeta =
      const VerificationMeta('loserItemId');
  @override
  late final GeneratedColumn<String> loserItemId = GeneratedColumn<String>(
      'loser_item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> createdAt =
      GeneratedColumn<DateTime>('created_at', aliasedName, false,
              type: DriftSqlType.dateTime,
              requiredDuringInsert: false,
              defaultValue: currentDateAndTime)
          .withConverter<DateTime>($LocalComparisonsTable.$convertercreatedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, winnerItemId, loserItemId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_comparisons';
  @override
  VerificationContext validateIntegrity(Insertable<LocalComparison> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('winner_item_id')) {
      context.handle(
          _winnerItemIdMeta,
          winnerItemId.isAcceptableOrUnknown(
              data['winner_item_id']!, _winnerItemIdMeta));
    } else if (isInserting) {
      context.missing(_winnerItemIdMeta);
    }
    if (data.containsKey('loser_item_id')) {
      context.handle(
          _loserItemIdMeta,
          loserItemId.isAcceptableOrUnknown(
              data['loser_item_id']!, _loserItemIdMeta));
    } else if (isInserting) {
      context.missing(_loserItemIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalComparison map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalComparison(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      winnerItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}winner_item_id'])!,
      loserItemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}loser_item_id'])!,
      createdAt: $LocalComparisonsTable.$convertercreatedAt.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!),
    );
  }

  @override
  $LocalComparisonsTable createAlias(String alias) {
    return $LocalComparisonsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $convertercreatedAt =
      const DateTimeCorrectionConverter();
}

class LocalComparison extends DataClass implements Insertable<LocalComparison> {
  final String id;
  final String userId;
  final String winnerItemId;
  final String loserItemId;
  final DateTime createdAt;
  const LocalComparison(
      {required this.id,
      required this.userId,
      required this.winnerItemId,
      required this.loserItemId,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['winner_item_id'] = Variable<String>(winnerItemId);
    map['loser_item_id'] = Variable<String>(loserItemId);
    {
      map['created_at'] = Variable<DateTime>(
          $LocalComparisonsTable.$convertercreatedAt.toSql(createdAt));
    }
    return map;
  }

  LocalComparisonsCompanion toCompanion(bool nullToAbsent) {
    return LocalComparisonsCompanion(
      id: Value(id),
      userId: Value(userId),
      winnerItemId: Value(winnerItemId),
      loserItemId: Value(loserItemId),
      createdAt: Value(createdAt),
    );
  }

  factory LocalComparison.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalComparison(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      winnerItemId: serializer.fromJson<String>(json['winnerItemId']),
      loserItemId: serializer.fromJson<String>(json['loserItemId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'winnerItemId': serializer.toJson<String>(winnerItemId),
      'loserItemId': serializer.toJson<String>(loserItemId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalComparison copyWith(
          {String? id,
          String? userId,
          String? winnerItemId,
          String? loserItemId,
          DateTime? createdAt}) =>
      LocalComparison(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        winnerItemId: winnerItemId ?? this.winnerItemId,
        loserItemId: loserItemId ?? this.loserItemId,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalComparison copyWithCompanion(LocalComparisonsCompanion data) {
    return LocalComparison(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      winnerItemId: data.winnerItemId.present
          ? data.winnerItemId.value
          : this.winnerItemId,
      loserItemId:
          data.loserItemId.present ? data.loserItemId.value : this.loserItemId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalComparison(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('winnerItemId: $winnerItemId, ')
          ..write('loserItemId: $loserItemId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, winnerItemId, loserItemId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalComparison &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.winnerItemId == this.winnerItemId &&
          other.loserItemId == this.loserItemId &&
          other.createdAt == this.createdAt);
}

class LocalComparisonsCompanion extends UpdateCompanion<LocalComparison> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> winnerItemId;
  final Value<String> loserItemId;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalComparisonsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.winnerItemId = const Value.absent(),
    this.loserItemId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalComparisonsCompanion.insert({
    required String id,
    required String userId,
    required String winnerItemId,
    required String loserItemId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        winnerItemId = Value(winnerItemId),
        loserItemId = Value(loserItemId);
  static Insertable<LocalComparison> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? winnerItemId,
    Expression<String>? loserItemId,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (winnerItemId != null) 'winner_item_id': winnerItemId,
      if (loserItemId != null) 'loser_item_id': loserItemId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalComparisonsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? winnerItemId,
      Value<String>? loserItemId,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return LocalComparisonsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      winnerItemId: winnerItemId ?? this.winnerItemId,
      loserItemId: loserItemId ?? this.loserItemId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (winnerItemId.present) {
      map['winner_item_id'] = Variable<String>(winnerItemId.value);
    }
    if (loserItemId.present) {
      map['loser_item_id'] = Variable<String>(loserItemId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(
          $LocalComparisonsTable.$convertercreatedAt.toSql(createdAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalComparisonsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('winnerItemId: $winnerItemId, ')
          ..write('loserItemId: $loserItemId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalReviewsTable extends LocalReviews
    with TableInfo<$LocalReviewsTable, LocalReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
      'item_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
      'body', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingSnapshotMeta =
      const VerificationMeta('ratingSnapshot');
  @override
  late final GeneratedColumn<double> ratingSnapshot = GeneratedColumn<double>(
      'rating_snapshot', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>('updated_at', aliasedName, false,
              type: DriftSqlType.dateTime,
              requiredDuringInsert: false,
              defaultValue: currentDateAndTime)
          .withConverter<DateTime>($LocalReviewsTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns =>
      [id, userId, itemId, body, ratingSnapshot, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_reviews';
  @override
  VerificationContext validateIntegrity(Insertable<LocalReview> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(_itemIdMeta,
          itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta));
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
          _bodyMeta, body.isAcceptableOrUnknown(data['body']!, _bodyMeta));
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('rating_snapshot')) {
      context.handle(
          _ratingSnapshotMeta,
          ratingSnapshot.isAcceptableOrUnknown(
              data['rating_snapshot']!, _ratingSnapshotMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalReview(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      itemId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_id'])!,
      body: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}body'])!,
      ratingSnapshot: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating_snapshot']),
      updatedAt: $LocalReviewsTable.$converterupdatedAt.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $LocalReviewsTable createAlias(String alias) {
    return $LocalReviewsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const DateTimeCorrectionConverter();
}

class LocalReview extends DataClass implements Insertable<LocalReview> {
  final String id;
  final String userId;
  final String itemId;
  final String body;
  final double? ratingSnapshot;
  final DateTime updatedAt;
  const LocalReview(
      {required this.id,
      required this.userId,
      required this.itemId,
      required this.body,
      this.ratingSnapshot,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['item_id'] = Variable<String>(itemId);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || ratingSnapshot != null) {
      map['rating_snapshot'] = Variable<double>(ratingSnapshot);
    }
    {
      map['updated_at'] = Variable<DateTime>(
          $LocalReviewsTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  LocalReviewsCompanion toCompanion(bool nullToAbsent) {
    return LocalReviewsCompanion(
      id: Value(id),
      userId: Value(userId),
      itemId: Value(itemId),
      body: Value(body),
      ratingSnapshot: ratingSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(ratingSnapshot),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalReview.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalReview(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      itemId: serializer.fromJson<String>(json['itemId']),
      body: serializer.fromJson<String>(json['body']),
      ratingSnapshot: serializer.fromJson<double?>(json['ratingSnapshot']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'itemId': serializer.toJson<String>(itemId),
      'body': serializer.toJson<String>(body),
      'ratingSnapshot': serializer.toJson<double?>(ratingSnapshot),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalReview copyWith(
          {String? id,
          String? userId,
          String? itemId,
          String? body,
          Value<double?> ratingSnapshot = const Value.absent(),
          DateTime? updatedAt}) =>
      LocalReview(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        itemId: itemId ?? this.itemId,
        body: body ?? this.body,
        ratingSnapshot:
            ratingSnapshot.present ? ratingSnapshot.value : this.ratingSnapshot,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalReview copyWithCompanion(LocalReviewsCompanion data) {
    return LocalReview(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      body: data.body.present ? data.body.value : this.body,
      ratingSnapshot: data.ratingSnapshot.present
          ? data.ratingSnapshot.value
          : this.ratingSnapshot,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalReview(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('body: $body, ')
          ..write('ratingSnapshot: $ratingSnapshot, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, userId, itemId, body, ratingSnapshot, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalReview &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.itemId == this.itemId &&
          other.body == this.body &&
          other.ratingSnapshot == this.ratingSnapshot &&
          other.updatedAt == this.updatedAt);
}

class LocalReviewsCompanion extends UpdateCompanion<LocalReview> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> itemId;
  final Value<String> body;
  final Value<double?> ratingSnapshot;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalReviewsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.itemId = const Value.absent(),
    this.body = const Value.absent(),
    this.ratingSnapshot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalReviewsCompanion.insert({
    required String id,
    required String userId,
    required String itemId,
    required String body,
    this.ratingSnapshot = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        userId = Value(userId),
        itemId = Value(itemId),
        body = Value(body);
  static Insertable<LocalReview> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? itemId,
    Expression<String>? body,
    Expression<double>? ratingSnapshot,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (itemId != null) 'item_id': itemId,
      if (body != null) 'body': body,
      if (ratingSnapshot != null) 'rating_snapshot': ratingSnapshot,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalReviewsCompanion copyWith(
      {Value<String>? id,
      Value<String>? userId,
      Value<String>? itemId,
      Value<String>? body,
      Value<double?>? ratingSnapshot,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalReviewsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      itemId: itemId ?? this.itemId,
      body: body ?? this.body,
      ratingSnapshot: ratingSnapshot ?? this.ratingSnapshot,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (ratingSnapshot.present) {
      map['rating_snapshot'] = Variable<double>(ratingSnapshot.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
          $LocalReviewsTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalReviewsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('itemId: $itemId, ')
          ..write('body: $body, ')
          ..write('ratingSnapshot: $ratingSnapshot, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalItemInfosTable extends LocalItemInfos
    with TableInfo<$LocalItemInfosTable, LocalItemInfo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalItemInfosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, DateTime> updatedAt =
      GeneratedColumn<DateTime>('updated_at', aliasedName, false,
              type: DriftSqlType.dateTime,
              requiredDuringInsert: false,
              defaultValue: currentDateAndTime)
          .withConverter<DateTime>($LocalItemInfosTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [key, json, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_item_infos';
  @override
  VerificationContext validateIntegrity(Insertable<LocalItemInfo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalItemInfo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalItemInfo(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      updatedAt: $LocalItemInfosTable.$converterupdatedAt.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!),
    );
  }

  @override
  $LocalItemInfosTable createAlias(String alias) {
    return $LocalItemInfosTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, DateTime> $converterupdatedAt =
      const DateTimeCorrectionConverter();
}

class LocalItemInfo extends DataClass implements Insertable<LocalItemInfo> {
  final String key;
  final String json;
  final DateTime updatedAt;
  const LocalItemInfo(
      {required this.key, required this.json, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['json'] = Variable<String>(json);
    {
      map['updated_at'] = Variable<DateTime>(
          $LocalItemInfosTable.$converterupdatedAt.toSql(updatedAt));
    }
    return map;
  }

  LocalItemInfosCompanion toCompanion(bool nullToAbsent) {
    return LocalItemInfosCompanion(
      key: Value(key),
      json: Value(json),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalItemInfo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalItemInfo(
      key: serializer.fromJson<String>(json['key']),
      json: serializer.fromJson<String>(json['json']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'json': serializer.toJson<String>(json),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalItemInfo copyWith({String? key, String? json, DateTime? updatedAt}) =>
      LocalItemInfo(
        key: key ?? this.key,
        json: json ?? this.json,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LocalItemInfo copyWithCompanion(LocalItemInfosCompanion data) {
    return LocalItemInfo(
      key: data.key.present ? data.key.value : this.key,
      json: data.json.present ? data.json.value : this.json,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemInfo(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, json, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalItemInfo &&
          other.key == this.key &&
          other.json == this.json &&
          other.updatedAt == this.updatedAt);
}

class LocalItemInfosCompanion extends UpdateCompanion<LocalItemInfo> {
  final Value<String> key;
  final Value<String> json;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalItemInfosCompanion({
    this.key = const Value.absent(),
    this.json = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalItemInfosCompanion.insert({
    required String key,
    required String json,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        json = Value(json);
  static Insertable<LocalItemInfo> custom({
    Expression<String>? key,
    Expression<String>? json,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (json != null) 'json': json,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalItemInfosCompanion copyWith(
      {Value<String>? key,
      Value<String>? json,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return LocalItemInfosCompanion(
      key: key ?? this.key,
      json: json ?? this.json,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(
          $LocalItemInfosTable.$converterupdatedAt.toSql(updatedAt.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalItemInfosCompanion(')
          ..write('key: $key, ')
          ..write('json: $json, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAliasesTable extends LocalAliases
    with TableInfo<$LocalAliasesTable, CanonicalAlias> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _naturalKeyMeta =
      const VerificationMeta('naturalKey');
  @override
  late final GeneratedColumn<String> naturalKey = GeneratedColumn<String>(
      'natural_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _canonicalKeyMeta =
      const VerificationMeta('canonicalKey');
  @override
  late final GeneratedColumn<String> canonicalKey = GeneratedColumn<String>(
      'canonical_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [naturalKey, canonicalKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_aliases';
  @override
  VerificationContext validateIntegrity(Insertable<CanonicalAlias> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('natural_key')) {
      context.handle(
          _naturalKeyMeta,
          naturalKey.isAcceptableOrUnknown(
              data['natural_key']!, _naturalKeyMeta));
    } else if (isInserting) {
      context.missing(_naturalKeyMeta);
    }
    if (data.containsKey('canonical_key')) {
      context.handle(
          _canonicalKeyMeta,
          canonicalKey.isAcceptableOrUnknown(
              data['canonical_key']!, _canonicalKeyMeta));
    } else if (isInserting) {
      context.missing(_canonicalKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {naturalKey};
  @override
  CanonicalAlias map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CanonicalAlias(
      naturalKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}natural_key'])!,
      canonicalKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}canonical_key'])!,
    );
  }

  @override
  $LocalAliasesTable createAlias(String alias) {
    return $LocalAliasesTable(attachedDatabase, alias);
  }
}

class CanonicalAlias extends DataClass implements Insertable<CanonicalAlias> {
  final String naturalKey;
  final String canonicalKey;
  const CanonicalAlias({required this.naturalKey, required this.canonicalKey});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['natural_key'] = Variable<String>(naturalKey);
    map['canonical_key'] = Variable<String>(canonicalKey);
    return map;
  }

  LocalAliasesCompanion toCompanion(bool nullToAbsent) {
    return LocalAliasesCompanion(
      naturalKey: Value(naturalKey),
      canonicalKey: Value(canonicalKey),
    );
  }

  factory CanonicalAlias.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CanonicalAlias(
      naturalKey: serializer.fromJson<String>(json['naturalKey']),
      canonicalKey: serializer.fromJson<String>(json['canonicalKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'naturalKey': serializer.toJson<String>(naturalKey),
      'canonicalKey': serializer.toJson<String>(canonicalKey),
    };
  }

  CanonicalAlias copyWith({String? naturalKey, String? canonicalKey}) =>
      CanonicalAlias(
        naturalKey: naturalKey ?? this.naturalKey,
        canonicalKey: canonicalKey ?? this.canonicalKey,
      );
  CanonicalAlias copyWithCompanion(LocalAliasesCompanion data) {
    return CanonicalAlias(
      naturalKey:
          data.naturalKey.present ? data.naturalKey.value : this.naturalKey,
      canonicalKey: data.canonicalKey.present
          ? data.canonicalKey.value
          : this.canonicalKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CanonicalAlias(')
          ..write('naturalKey: $naturalKey, ')
          ..write('canonicalKey: $canonicalKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(naturalKey, canonicalKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanonicalAlias &&
          other.naturalKey == this.naturalKey &&
          other.canonicalKey == this.canonicalKey);
}

class LocalAliasesCompanion extends UpdateCompanion<CanonicalAlias> {
  final Value<String> naturalKey;
  final Value<String> canonicalKey;
  final Value<int> rowid;
  const LocalAliasesCompanion({
    this.naturalKey = const Value.absent(),
    this.canonicalKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAliasesCompanion.insert({
    required String naturalKey,
    required String canonicalKey,
    this.rowid = const Value.absent(),
  })  : naturalKey = Value(naturalKey),
        canonicalKey = Value(canonicalKey);
  static Insertable<CanonicalAlias> custom({
    Expression<String>? naturalKey,
    Expression<String>? canonicalKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (naturalKey != null) 'natural_key': naturalKey,
      if (canonicalKey != null) 'canonical_key': canonicalKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAliasesCompanion copyWith(
      {Value<String>? naturalKey,
      Value<String>? canonicalKey,
      Value<int>? rowid}) {
    return LocalAliasesCompanion(
      naturalKey: naturalKey ?? this.naturalKey,
      canonicalKey: canonicalKey ?? this.canonicalKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (naturalKey.present) {
      map['natural_key'] = Variable<String>(naturalKey.value);
    }
    if (canonicalKey.present) {
      map['canonical_key'] = Variable<String>(canonicalKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAliasesCompanion(')
          ..write('naturalKey: $naturalKey, ')
          ..write('canonicalKey: $canonicalKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalItemsTable localItems = $LocalItemsTable(this);
  late final $LocalRatingsTable localRatings = $LocalRatingsTable(this);
  late final $LocalComparisonsTable localComparisons =
      $LocalComparisonsTable(this);
  late final $LocalReviewsTable localReviews = $LocalReviewsTable(this);
  late final $LocalItemInfosTable localItemInfos = $LocalItemInfosTable(this);
  late final $LocalAliasesTable localAliases = $LocalAliasesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        localItems,
        localRatings,
        localComparisons,
        localReviews,
        localItemInfos,
        localAliases
      ];
}

typedef $$LocalItemsTableCreateCompanionBuilder = LocalItemsCompanion Function({
  required String id,
  required String kind,
  required String source,
  required String sourceId,
  required String title,
  Value<String?> primaryArtist,
  Value<String?> imageUrl,
  Value<String> tags,
  Value<String?> canonicalKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$LocalItemsTableUpdateCompanionBuilder = LocalItemsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> source,
  Value<String> sourceId,
  Value<String> title,
  Value<String?> primaryArtist,
  Value<String?> imageUrl,
  Value<String> tags,
  Value<String?> canonicalKey,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalItemsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get primaryArtist => $composableBuilder(
      column: $table.primaryArtist, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$LocalItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind => $composableBuilder(
      column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source => $composableBuilder(
      column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get primaryArtist => $composableBuilder(
      column: $table.primaryArtist,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imageUrl => $composableBuilder(
      column: $table.imageUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalItemsTable> {
  $$LocalItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get primaryArtist => $composableBuilder(
      column: $table.primaryArtist, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalItemsTable,
    LocalItem,
    $$LocalItemsTableFilterComposer,
    $$LocalItemsTableOrderingComposer,
    $$LocalItemsTableAnnotationComposer,
    $$LocalItemsTableCreateCompanionBuilder,
    $$LocalItemsTableUpdateCompanionBuilder,
    (LocalItem, BaseReferences<_$AppDatabase, $LocalItemsTable, LocalItem>),
    LocalItem,
    PrefetchHooks Function()> {
  $$LocalItemsTableTableManager(_$AppDatabase db, $LocalItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> kind = const Value.absent(),
            Value<String> source = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> primaryArtist = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> canonicalKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalItemsCompanion(
            id: id,
            kind: kind,
            source: source,
            sourceId: sourceId,
            title: title,
            primaryArtist: primaryArtist,
            imageUrl: imageUrl,
            tags: tags,
            canonicalKey: canonicalKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String kind,
            required String source,
            required String sourceId,
            required String title,
            Value<String?> primaryArtist = const Value.absent(),
            Value<String?> imageUrl = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String?> canonicalKey = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalItemsCompanion.insert(
            id: id,
            kind: kind,
            source: source,
            sourceId: sourceId,
            title: title,
            primaryArtist: primaryArtist,
            imageUrl: imageUrl,
            tags: tags,
            canonicalKey: canonicalKey,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalItemsTable,
    LocalItem,
    $$LocalItemsTableFilterComposer,
    $$LocalItemsTableOrderingComposer,
    $$LocalItemsTableAnnotationComposer,
    $$LocalItemsTableCreateCompanionBuilder,
    $$LocalItemsTableUpdateCompanionBuilder,
    (LocalItem, BaseReferences<_$AppDatabase, $LocalItemsTable, LocalItem>),
    LocalItem,
    PrefetchHooks Function()>;
typedef $$LocalRatingsTableCreateCompanionBuilder = LocalRatingsCompanion
    Function({
  required String id,
  required String userId,
  required String itemId,
  Value<double> elo,
  Value<int> comparisons,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalRatingsTableUpdateCompanionBuilder = LocalRatingsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> itemId,
  Value<double> elo,
  Value<int> comparisons,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRatingsTable> {
  $$LocalRatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get elo => $composableBuilder(
      column: $table.elo, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get comparisons => $composableBuilder(
      column: $table.comparisons, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$LocalRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRatingsTable> {
  $$LocalRatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get elo => $composableBuilder(
      column: $table.elo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get comparisons => $composableBuilder(
      column: $table.comparisons, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRatingsTable> {
  $$LocalRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<double> get elo =>
      $composableBuilder(column: $table.elo, builder: (column) => column);

  GeneratedColumn<int> get comparisons => $composableBuilder(
      column: $table.comparisons, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalRatingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalRatingsTable,
    LocalRating,
    $$LocalRatingsTableFilterComposer,
    $$LocalRatingsTableOrderingComposer,
    $$LocalRatingsTableAnnotationComposer,
    $$LocalRatingsTableCreateCompanionBuilder,
    $$LocalRatingsTableUpdateCompanionBuilder,
    (
      LocalRating,
      BaseReferences<_$AppDatabase, $LocalRatingsTable, LocalRating>
    ),
    LocalRating,
    PrefetchHooks Function()> {
  $$LocalRatingsTableTableManager(_$AppDatabase db, $LocalRatingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<double> elo = const Value.absent(),
            Value<int> comparisons = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalRatingsCompanion(
            id: id,
            userId: userId,
            itemId: itemId,
            elo: elo,
            comparisons: comparisons,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String itemId,
            Value<double> elo = const Value.absent(),
            Value<int> comparisons = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalRatingsCompanion.insert(
            id: id,
            userId: userId,
            itemId: itemId,
            elo: elo,
            comparisons: comparisons,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalRatingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalRatingsTable,
    LocalRating,
    $$LocalRatingsTableFilterComposer,
    $$LocalRatingsTableOrderingComposer,
    $$LocalRatingsTableAnnotationComposer,
    $$LocalRatingsTableCreateCompanionBuilder,
    $$LocalRatingsTableUpdateCompanionBuilder,
    (
      LocalRating,
      BaseReferences<_$AppDatabase, $LocalRatingsTable, LocalRating>
    ),
    LocalRating,
    PrefetchHooks Function()>;
typedef $$LocalComparisonsTableCreateCompanionBuilder
    = LocalComparisonsCompanion Function({
  required String id,
  required String userId,
  required String winnerItemId,
  required String loserItemId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$LocalComparisonsTableUpdateCompanionBuilder
    = LocalComparisonsCompanion Function({
  Value<String> id,
  Value<String> userId,
  Value<String> winnerItemId,
  Value<String> loserItemId,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$LocalComparisonsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalComparisonsTable> {
  $$LocalComparisonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get winnerItemId => $composableBuilder(
      column: $table.winnerItemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get loserItemId => $composableBuilder(
      column: $table.loserItemId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get createdAt =>
      $composableBuilder(
          column: $table.createdAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$LocalComparisonsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalComparisonsTable> {
  $$LocalComparisonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get winnerItemId => $composableBuilder(
      column: $table.winnerItemId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get loserItemId => $composableBuilder(
      column: $table.loserItemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalComparisonsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalComparisonsTable> {
  $$LocalComparisonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get winnerItemId => $composableBuilder(
      column: $table.winnerItemId, builder: (column) => column);

  GeneratedColumn<String> get loserItemId => $composableBuilder(
      column: $table.loserItemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalComparisonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalComparisonsTable,
    LocalComparison,
    $$LocalComparisonsTableFilterComposer,
    $$LocalComparisonsTableOrderingComposer,
    $$LocalComparisonsTableAnnotationComposer,
    $$LocalComparisonsTableCreateCompanionBuilder,
    $$LocalComparisonsTableUpdateCompanionBuilder,
    (
      LocalComparison,
      BaseReferences<_$AppDatabase, $LocalComparisonsTable, LocalComparison>
    ),
    LocalComparison,
    PrefetchHooks Function()> {
  $$LocalComparisonsTableTableManager(
      _$AppDatabase db, $LocalComparisonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalComparisonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalComparisonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalComparisonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> winnerItemId = const Value.absent(),
            Value<String> loserItemId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalComparisonsCompanion(
            id: id,
            userId: userId,
            winnerItemId: winnerItemId,
            loserItemId: loserItemId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String winnerItemId,
            required String loserItemId,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalComparisonsCompanion.insert(
            id: id,
            userId: userId,
            winnerItemId: winnerItemId,
            loserItemId: loserItemId,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalComparisonsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalComparisonsTable,
    LocalComparison,
    $$LocalComparisonsTableFilterComposer,
    $$LocalComparisonsTableOrderingComposer,
    $$LocalComparisonsTableAnnotationComposer,
    $$LocalComparisonsTableCreateCompanionBuilder,
    $$LocalComparisonsTableUpdateCompanionBuilder,
    (
      LocalComparison,
      BaseReferences<_$AppDatabase, $LocalComparisonsTable, LocalComparison>
    ),
    LocalComparison,
    PrefetchHooks Function()>;
typedef $$LocalReviewsTableCreateCompanionBuilder = LocalReviewsCompanion
    Function({
  required String id,
  required String userId,
  required String itemId,
  required String body,
  Value<double?> ratingSnapshot,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalReviewsTableUpdateCompanionBuilder = LocalReviewsCompanion
    Function({
  Value<String> id,
  Value<String> userId,
  Value<String> itemId,
  Value<String> body,
  Value<double?> ratingSnapshot,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalReviewsTable> {
  $$LocalReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get ratingSnapshot => $composableBuilder(
      column: $table.ratingSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$LocalReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalReviewsTable> {
  $$LocalReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemId => $composableBuilder(
      column: $table.itemId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get body => $composableBuilder(
      column: $table.body, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get ratingSnapshot => $composableBuilder(
      column: $table.ratingSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalReviewsTable> {
  $$LocalReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<double> get ratingSnapshot => $composableBuilder(
      column: $table.ratingSnapshot, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalReviewsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalReviewsTable,
    LocalReview,
    $$LocalReviewsTableFilterComposer,
    $$LocalReviewsTableOrderingComposer,
    $$LocalReviewsTableAnnotationComposer,
    $$LocalReviewsTableCreateCompanionBuilder,
    $$LocalReviewsTableUpdateCompanionBuilder,
    (
      LocalReview,
      BaseReferences<_$AppDatabase, $LocalReviewsTable, LocalReview>
    ),
    LocalReview,
    PrefetchHooks Function()> {
  $$LocalReviewsTableTableManager(_$AppDatabase db, $LocalReviewsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<String> itemId = const Value.absent(),
            Value<String> body = const Value.absent(),
            Value<double?> ratingSnapshot = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReviewsCompanion(
            id: id,
            userId: userId,
            itemId: itemId,
            body: body,
            ratingSnapshot: ratingSnapshot,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String userId,
            required String itemId,
            required String body,
            Value<double?> ratingSnapshot = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalReviewsCompanion.insert(
            id: id,
            userId: userId,
            itemId: itemId,
            body: body,
            ratingSnapshot: ratingSnapshot,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalReviewsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalReviewsTable,
    LocalReview,
    $$LocalReviewsTableFilterComposer,
    $$LocalReviewsTableOrderingComposer,
    $$LocalReviewsTableAnnotationComposer,
    $$LocalReviewsTableCreateCompanionBuilder,
    $$LocalReviewsTableUpdateCompanionBuilder,
    (
      LocalReview,
      BaseReferences<_$AppDatabase, $LocalReviewsTable, LocalReview>
    ),
    LocalReview,
    PrefetchHooks Function()>;
typedef $$LocalItemInfosTableCreateCompanionBuilder = LocalItemInfosCompanion
    Function({
  required String key,
  required String json,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$LocalItemInfosTableUpdateCompanionBuilder = LocalItemInfosCompanion
    Function({
  Value<String> key,
  Value<String> json,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$LocalItemInfosTableFilterComposer
    extends Composer<_$AppDatabase, $LocalItemInfosTable> {
  $$LocalItemInfosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<DateTime, DateTime, DateTime> get updatedAt =>
      $composableBuilder(
          column: $table.updatedAt,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$LocalItemInfosTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalItemInfosTable> {
  $$LocalItemInfosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$LocalItemInfosTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalItemInfosTable> {
  $$LocalItemInfosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalItemInfosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalItemInfosTable,
    LocalItemInfo,
    $$LocalItemInfosTableFilterComposer,
    $$LocalItemInfosTableOrderingComposer,
    $$LocalItemInfosTableAnnotationComposer,
    $$LocalItemInfosTableCreateCompanionBuilder,
    $$LocalItemInfosTableUpdateCompanionBuilder,
    (
      LocalItemInfo,
      BaseReferences<_$AppDatabase, $LocalItemInfosTable, LocalItemInfo>
    ),
    LocalItemInfo,
    PrefetchHooks Function()> {
  $$LocalItemInfosTableTableManager(
      _$AppDatabase db, $LocalItemInfosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalItemInfosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalItemInfosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalItemInfosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalItemInfosCompanion(
            key: key,
            json: json,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String json,
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalItemInfosCompanion.insert(
            key: key,
            json: json,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalItemInfosTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalItemInfosTable,
    LocalItemInfo,
    $$LocalItemInfosTableFilterComposer,
    $$LocalItemInfosTableOrderingComposer,
    $$LocalItemInfosTableAnnotationComposer,
    $$LocalItemInfosTableCreateCompanionBuilder,
    $$LocalItemInfosTableUpdateCompanionBuilder,
    (
      LocalItemInfo,
      BaseReferences<_$AppDatabase, $LocalItemInfosTable, LocalItemInfo>
    ),
    LocalItemInfo,
    PrefetchHooks Function()>;
typedef $$LocalAliasesTableCreateCompanionBuilder = LocalAliasesCompanion
    Function({
  required String naturalKey,
  required String canonicalKey,
  Value<int> rowid,
});
typedef $$LocalAliasesTableUpdateCompanionBuilder = LocalAliasesCompanion
    Function({
  Value<String> naturalKey,
  Value<String> canonicalKey,
  Value<int> rowid,
});

class $$LocalAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAliasesTable> {
  $$LocalAliasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get naturalKey => $composableBuilder(
      column: $table.naturalKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey, builder: (column) => ColumnFilters(column));
}

class $$LocalAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAliasesTable> {
  $$LocalAliasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get naturalKey => $composableBuilder(
      column: $table.naturalKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey,
      builder: (column) => ColumnOrderings(column));
}

class $$LocalAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAliasesTable> {
  $$LocalAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get naturalKey => $composableBuilder(
      column: $table.naturalKey, builder: (column) => column);

  GeneratedColumn<String> get canonicalKey => $composableBuilder(
      column: $table.canonicalKey, builder: (column) => column);
}

class $$LocalAliasesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalAliasesTable,
    CanonicalAlias,
    $$LocalAliasesTableFilterComposer,
    $$LocalAliasesTableOrderingComposer,
    $$LocalAliasesTableAnnotationComposer,
    $$LocalAliasesTableCreateCompanionBuilder,
    $$LocalAliasesTableUpdateCompanionBuilder,
    (
      CanonicalAlias,
      BaseReferences<_$AppDatabase, $LocalAliasesTable, CanonicalAlias>
    ),
    CanonicalAlias,
    PrefetchHooks Function()> {
  $$LocalAliasesTableTableManager(_$AppDatabase db, $LocalAliasesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> naturalKey = const Value.absent(),
            Value<String> canonicalKey = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAliasesCompanion(
            naturalKey: naturalKey,
            canonicalKey: canonicalKey,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String naturalKey,
            required String canonicalKey,
            Value<int> rowid = const Value.absent(),
          }) =>
              LocalAliasesCompanion.insert(
            naturalKey: naturalKey,
            canonicalKey: canonicalKey,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalAliasesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $LocalAliasesTable,
    CanonicalAlias,
    $$LocalAliasesTableFilterComposer,
    $$LocalAliasesTableOrderingComposer,
    $$LocalAliasesTableAnnotationComposer,
    $$LocalAliasesTableCreateCompanionBuilder,
    $$LocalAliasesTableUpdateCompanionBuilder,
    (
      CanonicalAlias,
      BaseReferences<_$AppDatabase, $LocalAliasesTable, CanonicalAlias>
    ),
    CanonicalAlias,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalItemsTableTableManager get localItems =>
      $$LocalItemsTableTableManager(_db, _db.localItems);
  $$LocalRatingsTableTableManager get localRatings =>
      $$LocalRatingsTableTableManager(_db, _db.localRatings);
  $$LocalComparisonsTableTableManager get localComparisons =>
      $$LocalComparisonsTableTableManager(_db, _db.localComparisons);
  $$LocalReviewsTableTableManager get localReviews =>
      $$LocalReviewsTableTableManager(_db, _db.localReviews);
  $$LocalItemInfosTableTableManager get localItemInfos =>
      $$LocalItemInfosTableTableManager(_db, _db.localItemInfos);
  $$LocalAliasesTableTableManager get localAliases =>
      $$LocalAliasesTableTableManager(_db, _db.localAliases);
}
