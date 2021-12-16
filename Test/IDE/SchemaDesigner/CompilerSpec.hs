{-|
Module: Test.IDE.SchemaDesigner.CompilerSpec
Copyright: (c) digitally induced GmbH, 2020
-}
module Test.IDE.SchemaDesigner.CompilerSpec where

import Test.Hspec
import IHP.Prelude
import  IHP.IDE.SchemaDesigner.Compiler (compileSql)
import IHP.IDE.SchemaDesigner.Types
import IHP.ViewPrelude (cs, plain)
import qualified Text.Megaparsec as Megaparsec
import Test.IDE.SchemaDesigner.ParserSpec (col, parseSql)

tests = do
    describe "The Schema.sql Compiler" do
        it "should compile an empty CREATE TABLE statement" do
            compileSql [StatementCreateTable CreateTable { name = "users", columns = [], primaryKeyConstraint = PrimaryKeyConstraint [], constraints = [] }] `shouldBe` "CREATE TABLE users (\n\n);\n"

        it "should compile a CREATE EXTENSION for the UUID extension" do
            compileSql [CreateExtension { name = "uuid-ossp", ifNotExists = True }] `shouldBe` "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";\n"

        it "should compile a line comment" do
            compileSql [Comment { content = " Comment value" }] `shouldBe` "-- Comment value\n"
        
        it "should compile a empty line comments" do
            compileSql [Comment { content = "" }, Comment { content = "" }] `shouldBe` "--\n--\n"

        it "should compile a CREATE TABLE with columns" do
            let sql = cs [plain|CREATE TABLE users (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    firstname TEXT NOT NULL,
    lastname TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    email TEXT NOT NULL,
    company_id UUID NOT NULL,
    picture_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);
|]
            let statement = StatementCreateTable CreateTable
                    { name = "users"
                    , columns = [
                        Column
                            { name = "id"
                            , columnType = PUUID
                            , defaultValue = Just (CallExpression "uuid_generate_v4" [])
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "firstname"
                            , columnType = PText
                            , defaultValue = Nothing
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "lastname"
                            , columnType = PText
                            , defaultValue = Nothing
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "password_hash"
                            , columnType = PText
                            , defaultValue = Nothing
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "email"
                            , columnType = PText
                            , defaultValue = Nothing
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "company_id"
                            , columnType = PUUID
                            , defaultValue = Nothing
                            , notNull = True
                            , isUnique = False
                            }
                        , Column
                            { name = "picture_url"
                            , columnType = PText
                            , defaultValue = Nothing
                            , notNull = False
                            , isUnique = False
                            }
                        , Column
                            { name = "created_at"
                            , columnType = PTimestampWithTimezone
                            , defaultValue = Just (CallExpression "NOW" [])
                            , notNull = True
                            , isUnique = False
                            }
                        ]
                    , primaryKeyConstraint = PrimaryKeyConstraint ["id"]
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE with quoted identifiers" do
            compileSql [StatementCreateTable CreateTable { name = "quoted name", columns = [], primaryKeyConstraint = PrimaryKeyConstraint [], constraints = [] }] `shouldBe` "CREATE TABLE \"quoted name\" (\n\n);\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. ON DELETE CASCADE" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Just Cascade
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE CASCADE;\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. ON DELETE SET DEFAULT" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Just SetDefault
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE SET DEFAULT;\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. ON DELETE SET NULL" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Just SetNull
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE SET NULL;\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. ON DELETE RESTRICT" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Just Restrict
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE RESTRICT;\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. ON DELETE NO ACTION" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Just NoAction
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ON DELETE NO ACTION;\n"

        it "should compile ALTER TABLE .. ADD FOREIGN KEY .. (without ON DELETE)" do
            let statement = AddConstraint
                    { tableName = "users"
                    , constraintName = "users_ref_company_id"
                    , constraint = ForeignKeyConstraint
                        { columnName = "company_id"
                        , referenceTable = "companies"
                        , referenceColumn = "id"
                        , onDelete = Nothing
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE users ADD CONSTRAINT users_ref_company_id FOREIGN KEY (company_id) REFERENCES companies (id) ;\n"

        it "should compile ALTER TABLE .. ADD CONSTRAINT .. CHECK .." do
            let statement = AddConstraint
                    { tableName = "posts"
                    , constraintName = "check_title_length"
                    , constraint = CheckConstraint
                        { checkExpression = NotEqExpression (VarExpression "title") (TextExpression "")
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE posts ADD CONSTRAINT check_title_length CHECK (title <> '');\n"

        it "should compile a complex ALTER TABLE .. ADD CONSTRAINT .. CHECK .." do
            let statement = AddConstraint
                    { tableName = "properties"
                    , constraintName = "foobar"
                    , constraint = CheckConstraint
                        { checkExpression = OrExpression
                                (AndExpression
                                    (AndExpression
                                        (EqExpression (VarExpression "property_type") (TextExpression "haus_buy"))
                                        (IsExpression (VarExpression "area_garden") (NotExpression (VarExpression "NULL")))
                                    )
                                    (IsExpression (VarExpression "rent_monthly") (VarExpression "NULL"))
                                )

                                (AndExpression
                                    (AndExpression
                                        (EqExpression (VarExpression "property_type") (TextExpression "haus_rent"))
                                        (IsExpression (VarExpression "rent_monthly") (NotExpression (VarExpression "NULL")))
                                    )
                                    (IsExpression (VarExpression "price") (VarExpression "NULL"))
                                )
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE properties ADD CONSTRAINT foobar CHECK ((property_type = 'haus_buy' AND area_garden IS NOT NULL AND rent_monthly IS NULL) OR (property_type = 'haus_rent' AND rent_monthly IS NOT NULL AND price IS NULL));\n"

        it "should compile ALTER TABLE .. ADD CONSTRAINT .. CHECK .. with a <" do
            let statement = AddConstraint
                    { tableName = "posts"
                    , constraintName = "check_title_length"
                    , constraint = CheckConstraint
                        { checkExpression = LessThanExpression (CallExpression ("length") [VarExpression "title"]) (VarExpression "20")
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE posts ADD CONSTRAINT check_title_length CHECK (length(title) < 20);\n"

        it "should compile ALTER TABLE .. ADD CONSTRAINT .. CHECK .. with a <=" do
            let statement = AddConstraint
                    { tableName = "posts"
                    , constraintName = "check_title_length"
                    , constraint = CheckConstraint
                        { checkExpression = LessThanOrEqualToExpression (CallExpression ("length") [VarExpression "title"]) (VarExpression "20")
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE posts ADD CONSTRAINT check_title_length CHECK (length(title) <= 20);\n"

        it "should compile ALTER TABLE .. ADD CONSTRAINT .. CHECK .. with a >" do
            let statement = AddConstraint
                    { tableName = "posts"
                    , constraintName = "check_title_length"
                    , constraint = CheckConstraint
                        { checkExpression = GreaterThanExpression (CallExpression ("length") [VarExpression "title"]) (VarExpression "20")
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE posts ADD CONSTRAINT check_title_length CHECK (length(title) > 20);\n"

        it "should compile ALTER TABLE .. ADD CONSTRAINT .. CHECK .. with a >=" do
            let statement = AddConstraint
                    { tableName = "posts"
                    , constraintName = "check_title_length"
                    , constraint = CheckConstraint
                        { checkExpression = GreaterThanOrEqualToExpression (CallExpression ("length") [VarExpression "title"]) (VarExpression "20")
                        }
                    }
            compileSql [statement] `shouldBe` "ALTER TABLE posts ADD CONSTRAINT check_title_length CHECK (length(title) >= 20);\n"

        it "should compile a CREATE TABLE with text default value in columns" do
            let sql = cs [plain|CREATE TABLE a (\n    content TEXT DEFAULT 'example text' NOT NULL\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "a"
                    , columns = [
                        Column
                            { name = "content"
                            , columnType = PText
                            , defaultValue = Just (TextExpression "example text")
                            , notNull = True
                            , isUnique = False
                            }
                        ]
                    , primaryKeyConstraint = PrimaryKeyConstraint []
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TYPE .. AS ENUM" do
            let sql = cs [plain|CREATE TYPE colors AS ENUM ('yellow', 'red', 'blue');\n|]
            let statement = CreateEnumType
                    { name = "colors"
                    , values = ["yellow", "red", "blue"]
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE with (deprecated) NUMERIC, NUMERIC(x), NUMERIC (x,y), VARYING(n) columns" do
            let sql = cs [plain|CREATE TABLE deprecated_variables (\n    a NUMERIC,\n    b NUMERIC(1),\n    c NUMERIC(1,2),\n    d CHARACTER VARYING(10)\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "deprecated_variables"
                    , columns =
                        [ Column
                            { name = "a"
                            , columnType = (PNumeric Nothing Nothing)
                            , defaultValue = Nothing
                            , notNull = False
                            , isUnique = False
                            }
                        , Column
                            { name = "b"
                            , columnType = (PNumeric (Just 1) Nothing)
                            , defaultValue = Nothing
                            , notNull = False
                            , isUnique = False
                            }
                        , Column
                            { name = "c"
                            , columnType = (PNumeric (Just 1) (Just 2))
                            , defaultValue = Nothing
                            , notNull = False
                            , isUnique = False
                            }
                        , Column
                            { name = "d"
                            , columnType = (PVaryingN (Just 10))
                            , defaultValue = Nothing
                            , notNull = False
                            , isUnique = False
                            }
                        ]
                    , primaryKeyConstraint = PrimaryKeyConstraint []
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with a multi-column UNIQUE (a, b) constraint" do
            let sql = cs [plain|CREATE TABLE user_followers (\n    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,\n    user_id UUID NOT NULL,\n    follower_id UUID NOT NULL,\n    UNIQUE(user_id, follower_id)\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "user_followers"
                    , columns =
                        [ col { name = "id", columnType = PUUID, defaultValue = Just (CallExpression "uuid_generate_v4" []), notNull = True }
                        , col { name = "user_id", columnType = PUUID, notNull = True }
                        , col { name = "follower_id", columnType = PUUID, notNull = True }
                        ]
                    , primaryKeyConstraint = PrimaryKeyConstraint ["id"]
                    , constraints = [ UniqueConstraint { columnNames = [ "user_id", "follower_id" ] } ]
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with a serial id" do
            let sql = cs [plain|CREATE TABLE orders (\n    id SERIAL PRIMARY KEY NOT NULL\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "orders"
                    , columns = [ col { name = "id", columnType = PSerial, notNull = True} ]
                    , primaryKeyConstraint = PrimaryKeyConstraint ["id"]
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with a bigserial id" do
            let sql = cs [plain|CREATE TABLE orders (\n    id BIGSERIAL PRIMARY KEY NOT NULL\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "orders"
                    , columns = [ col { name = "id", columnType = PBigserial, notNull = True} ]
                    , primaryKeyConstraint = PrimaryKeyConstraint ["id"]
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with a composite primary key" do
            let sql = cs [plain|CREATE TABLE orderTrucks (\n    order_id BIGSERIAL NOT NULL,\n    truck_id BIGSERIAL NOT NULL,\n    PRIMARY KEY(order_id, truck_id)\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "orderTrucks"
                    , columns =
                        [ col { name = "order_id", columnType = PBigserial, notNull = True}
                        , col { name = "truck_id", columnType = PBigserial, notNull = True}
                        ]
                    , primaryKeyConstraint = PrimaryKeyConstraint ["order_id", "truck_id"]
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with an array column" do
            let sql = cs [plain|CREATE TABLE array_tests (\n    pay_by_quarter INT[]\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "array_tests"
                    , columns = [ col { name = "pay_by_quarter", columnType = PArray PInt } ]
                    , primaryKeyConstraint = PrimaryKeyConstraint []
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE TABLE statement with an point column" do
            let sql = cs [plain|CREATE TABLE point_tests (\n    pos POINT\n);\n|]
            let statement = StatementCreateTable CreateTable
                    { name = "point_tests"
                    , columns = [ col { name = "pos", columnType = PPoint } ]
                    , primaryKeyConstraint = PrimaryKeyConstraint []
                    , constraints = []
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE INDEX statement" do
            let sql = cs [plain|CREATE INDEX users_index ON users (user_name);\n|]
            let statement = CreateIndex
                    { indexName = "users_index"
                    , unique = False
                    , tableName = "users"
                    , expressions = [VarExpression "user_name"]
                    , whereClause = Nothing
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE INDEX statement with multiple columns" do
            let sql = cs [plain|CREATE INDEX users_index ON users (user_name, project_id);\n|]
            let statement = CreateIndex
                    { indexName = "users_index"
                    , unique = False
                    , tableName = "users"
                    , expressions = [VarExpression "user_name", VarExpression "project_id"]
                    , whereClause = Nothing
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE INDEX statement with a LOWER call" do
            let sql = cs [plain|CREATE INDEX users_email_index ON users (LOWER(email));\n|]
            let statement = CreateIndex
                    { indexName = "users_email_index"
                    , unique = False
                    , tableName = "users"
                    , expressions = [CallExpression "LOWER" [VarExpression "email"]]
                    , whereClause = Nothing
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE UNIQUE INDEX statement" do
            let sql = cs [plain|CREATE UNIQUE INDEX users_index ON users (user_name);\n|]
            let statement = CreateIndex
                    { indexName = "users_index"
                    , unique = True
                    , tableName = "users"
                    , expressions = [VarExpression "user_name"]
                    , whereClause = Nothing
                    }
            compileSql [statement] `shouldBe` sql

        it "should compile a CREATE OR REPLACE FUNCTION ..() RETURNS TRIGGER .." do
            let sql = cs [plain|CREATE OR REPLACE FUNCTION notify_did_insert_webrtc_connection() RETURNS TRIGGER AS $$ BEGIN PERFORM pg_notify('did_insert_webrtc_connection', json_build_object('id', NEW.id, 'floor_id', NEW.floor_id, 'source_user_id', NEW.source_user_id, 'target_user_id', NEW.target_user_id)::text); RETURN NEW; END; $$ language plpgsql;\n|]
            let statement = CreateFunction
                    { functionName = "notify_did_insert_webrtc_connection"
                    , functionBody = " BEGIN PERFORM pg_notify('did_insert_webrtc_connection', json_build_object('id', NEW.id, 'floor_id', NEW.floor_id, 'source_user_id', NEW.source_user_id, 'target_user_id', NEW.target_user_id)::text); RETURN NEW; END; "
                    , orReplace = True
                    , returns = PTrigger
                    , language = "plpgsql"
                    }

            compileSql [statement] `shouldBe` sql


        it "should compile a CREATE FUNCTION ..() RETURNS TRIGGER .." do
            let sql = cs [plain|CREATE FUNCTION notify_did_insert_webrtc_connection() RETURNS TRIGGER AS $$ BEGIN PERFORM pg_notify('did_insert_webrtc_connection', json_build_object('id', NEW.id, 'floor_id', NEW.floor_id, 'source_user_id', NEW.source_user_id, 'target_user_id', NEW.target_user_id)::text); RETURN NEW; END; $$ language plpgsql;\n|]
            let statement = CreateFunction
                    { functionName = "notify_did_insert_webrtc_connection"
                    , functionBody = " BEGIN PERFORM pg_notify('did_insert_webrtc_connection', json_build_object('id', NEW.id, 'floor_id', NEW.floor_id, 'source_user_id', NEW.source_user_id, 'target_user_id', NEW.target_user_id)::text); RETURN NEW; END; "
                    , orReplace = False
                    , returns = PTrigger
                    , language = "plpgsql"
                    }

            compileSql [statement] `shouldBe` sql


        it "should compile a CREATE TRIGGER .." do
            let sql = cs [plain|CREATE TRIGGER t AFTER INSERT ON x FOR EACH ROW EXECUTE PROCEDURE y();\n|]
            let statement = UnknownStatement { raw = "CREATE TRIGGER t AFTER INSERT ON x FOR EACH ROW EXECUTE PROCEDURE y()"  }
            compileSql [statement] `shouldBe` sql

        it "should compile a decimal default value with a type-cast" do
            let sql = "CREATE TABLE a (\n    electricity_unit_price DOUBLE PRECISION DEFAULT 0.17::DOUBLE PRECISION NOT NULL\n);\n"
            let statement = StatementCreateTable CreateTable { name = "a", columns = [Column {name = "electricity_unit_price", columnType = PDouble, defaultValue = Just (TypeCastExpression (DoubleExpression 0.17) PDouble), notNull = True, isUnique = False}], primaryKeyConstraint = PrimaryKeyConstraint [], constraints = [] }
            compileSql [statement] `shouldBe` sql

        it "should compile a integer default value" do
            let sql = "CREATE TABLE a (\n    electricity_unit_price INT DEFAULT 0 NOT NULL\n);\n"
            let statement = StatementCreateTable CreateTable { name = "a", columns = [Column {name = "electricity_unit_price", columnType = PInt, defaultValue = Just (IntExpression 0), notNull = True, isUnique = False}], primaryKeyConstraint = PrimaryKeyConstraint [], constraints = [] }
            compileSql [statement] `shouldBe` sql

        it "should compile a partial index" do
            let sql = cs [plain|CREATE UNIQUE INDEX unique_source_id ON listings (source, source_id) WHERE source IS NOT NULL AND source_id IS NOT NULL;\n|]
            let index = CreateIndex
                    { indexName = "unique_source_id"
                    , unique = True
                    , tableName = "listings"
                    , expressions = [ VarExpression "source", VarExpression "source_id" ]
                    , whereClause = Just (
                        AndExpression
                            (IsExpression (VarExpression "source") (NotExpression (VarExpression "NULL")))
                            (IsExpression (VarExpression "source_id") (NotExpression (VarExpression "NULL"))))
                    }
            compileSql [index] `shouldBe` sql

        it "should compile 'ENABLE ROW LEVEL SECURITY' statements" do
            let sql = "ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;\n"
            let statements = [EnableRowLevelSecurity { tableName = "tasks" }]
            compileSql statements `shouldBe` sql

        it "should compile 'CREATE POLICY' statements" do
            let sql = "CREATE POLICY \"Users can manage their tasks\" ON tasks USING (user_id = ihp_user_id()) WITH CHECK (user_id = ihp_user_id());\n"
            let policy = CreatePolicy
                    { name = "Users can manage their tasks"
                    , tableName = "tasks"
                    , using = Just (
                        EqExpression
                            (VarExpression "user_id")
                            (CallExpression "ihp_user_id" [])
                        )
                    , check = Just (
                        EqExpression
                            (VarExpression "user_id")
                            (CallExpression "ihp_user_id" [])
                        )
                    }
            compileSql [policy] `shouldBe` sql

        it "should use parentheses where needed" do
            -- https://github.com/digitallyinduced/ihp/issues/1087
            let inputSql = cs [plain|ALTER TABLE listings ADD CONSTRAINT source CHECK ((NOT (user_id IS NOT NULL AND agent_id IS NOT NULL)) AND (user_id IS NOT NULL OR agent_id IS NOT NULL));\n|]
            compileSql [parseSql inputSql] `shouldBe` inputSql

        it "should compile 'ALTER TABLE .. DROP COLUMN ..' statements" do
            let sql = "ALTER TABLE tasks DROP COLUMN description;\n"
            let statements = [ DropColumn { tableName = "tasks", columnName = "description" } ]
            compileSql statements `shouldBe` sql
        
        it "should compile 'DROP TABLE ..' statements" do
            let sql = "DROP TABLE tasks;\n"
            let statements = [ DropTable { tableName = "tasks" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'CREATE SEQUENCE ..' statements" do
            let sql = "CREATE SEQUENCE a;\n"
            let statements = [ CreateSequence { name = "a" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. RENAME COLUMN .. TO ..' statements" do
            let sql = "ALTER TABLE users RENAME COLUMN name TO full_name;\n"
            let statements = [ RenameColumn { tableName = "users", from = "name", to = "full_name" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. ADD UNIQUE (..);' statements" do
            let sql = "ALTER TABLE users ADD UNIQUE (full_name);\n"
            let statements = [ AddConstraint { tableName = "users", constraintName = "", constraint = UniqueConstraint { columnNames = ["full_name"] }  } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. DROP CONSTRAINT ..;' statements" do
            let sql = "ALTER TABLE users DROP CONSTRAINT users_full_name_key;\n"
            let statements = [ DropConstraint { tableName = "users", constraintName = "users_full_name_key" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'DROP TYPE ..;' statements" do
            let sql = "DROP TYPE colors;\n"
            let statements = [ DropEnumType { name = "colors" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'DROP INDEX ..;' statements" do
            let sql = "DROP INDEX a;\n"
            let statements = [ DropIndex { indexName = "a" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. ALTER COLUMN .. DROP NOT NULL;' statements" do
            let sql = "ALTER TABLE users ALTER COLUMN email DROP NOT NULL;\n"
            let statements = [ DropNotNull { tableName = "users", columnName = "email" } ]
            compileSql statements `shouldBe` sql
        
        it "should compile 'ALTER TABLE .. ALTER COLUMN .. SET NOT NULL;' statements" do
            let sql = "ALTER TABLE users ALTER COLUMN email SET NOT NULL;\n"
            let statements = [ SetNotNull { tableName = "users", columnName = "email" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. ALTER COLUMN .. SET DEFAULT ..;' statements" do
            let sql = "ALTER TABLE users ALTER COLUMN email SET DEFAULT null;\n"
            let statements = [ SetDefaultValue { tableName = "users", columnName = "email", value = VarExpression "null" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'ALTER TABLE .. RENAME TO ..;' statements" do
            let sql = "ALTER TABLE profiles RENAME TO users;\n"
            let statements = [ RenameTable { from = "profiles", to = "users" } ]
            compileSql statements `shouldBe` sql
        
        it "should compile 'DROP POLICY .. ON ..;' statements" do
            let sql = "DROP POLICY \"Users can manage their todos\" ON todos;\n"
            let statements = [ DropPolicy { tableName = "todos", policyName = "Users can manage their todos" } ]
            compileSql statements `shouldBe` sql

        it "should compile 'CREATE EXTENSION IF NOT EXISTS;' statements with an unqualified name" do
            let sql = "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;\n"
            let statements = [ CreateExtension { name = "fuzzystrmatch", ifNotExists = True } ]
            compileSql statements `shouldBe` sql

        it "should compile 'CREATE POLICY ..;' statements with an EXISTS condition" do
            let sql = cs [plain|CREATE POLICY "Users can manage their project's migrations" ON migrations USING (EXISTS (SELECT 1 FROM public.projects WHERE projects.id = migrations.project_id)) WITH CHECK (EXISTS (SELECT 1 FROM public.projects WHERE projects.id = migrations.project_id));\n|]
            let statements =
                    [ CreatePolicy
                        { name = "Users can manage their project's migrations"
                        , tableName = "migrations"
                        , using = Just (ExistsExpression (SelectExpression (Select {columns = [IntExpression 1], from = DotExpression (VarExpression "public") "projects", whereClause = EqExpression (DotExpression (VarExpression "projects") "id") (DotExpression (VarExpression "migrations") "project_id")})))
                        , check = Just (ExistsExpression (SelectExpression (Select {columns = [IntExpression 1], from = DotExpression (VarExpression "public") "projects", whereClause = EqExpression (DotExpression (VarExpression "projects") "id") (DotExpression (VarExpression "migrations") "project_id")})))
                        }
                    ]
            compileSql statements `shouldBe` sql
