//
//  ContentUserModelMigrationManager.swift
//

import Foundation
import Fluent

public struct ContentUserModelMigrationManager<D> where D: JoinSupporting & SchemaSupporting & MigrationSupporting {
    public typealias Database = D

    public static func configureMigrations( migrations : inout MigrationConfig, forDatabase database: DatabaseIdentifier<Database>){
        
        User<Database>.defaultDatabase = database
        UserType<Database>.defaultDatabase = database
        UserNetworkJoin<Database>.defaultDatabase = database
        Network<Database>.defaultDatabase = database
        migrations.add(migration: ContentaUserMigration_01.self, database: database)
        
        AccessToken<Database>.defaultDatabase = database
        AccessTokenType<Database>.defaultDatabase = database
        migrations.add(migration: ContentaUserMigration_02.self, database: database)
    }
}
