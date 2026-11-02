import Foundation

enum Photos {
    static let sql = """
    SELECT a.ZADDEDDATE, a.ZDATECREATED, a.ZKIND, a.ZISDETECTEDSCREENSHOT, a.ZKINDSUBTYPE,
      a.ZUNIFORMTYPEIDENTIFIER, a.ZWIDTH, a.ZHEIGHT, x.ZORIGINALFILENAME, x.ZTITLE,
      x.ZACCESSIBILITYDESCRIPTION,
      coalesce(x.ZIMPORTEDBYDISPLAYNAME, x.ZIMPORTEDBYBUNDLEIDENTIFIER) AS imported_by
    FROM ZASSET a
    LEFT JOIN ZADDITIONALASSETATTRIBUTES x ON x.ZASSET = a.Z_PK
    WHERE a.ZADDEDDATE >= ? AND a.ZADDEDDATE < ? AND a.ZTRASHEDSTATE = 0 AND a.ZHIDDEN = 0
    ORDER BY a.ZADDEDDATE DESC, a.Z_PK DESC
    LIMIT ? OFFSET ?
    """

    static func run(_ query: Query) throws -> [String: Any] {
        let database = try Database(path: Paths.photos)
        let bindings: [Any] = [query.appleStart, query.appleEnd] + query.pageBindings
        return query.page(try database.rows(sql, bindings)) { row in
            [
                "added": Query.apple(row["ZADDEDDATE"]),
                "created": Query.apple(row["ZDATECREATED"]),
                "kind": row["ZKIND"] as? Int64 == 1 ? "video" : "photo",
                "screenshot": row["ZISDETECTEDSCREENSHOT"] as? Int64 == 1 || row["ZKINDSUBTYPE"] as? Int64 == 10,
                "type": row["ZUNIFORMTYPEIDENTIFIER"] ?? NSNull(),
                "width": row["ZWIDTH"] ?? NSNull(),
                "height": row["ZHEIGHT"] ?? NSNull(),
                "original_filename": row["ZORIGINALFILENAME"] ?? NSNull(),
                "title": row["ZTITLE"] ?? NSNull(),
                "description": row["ZACCESSIBILITYDESCRIPTION"] ?? NSNull(),
                "imported_by": row["imported_by"] ?? NSNull(),
            ]
        }
    }
}
