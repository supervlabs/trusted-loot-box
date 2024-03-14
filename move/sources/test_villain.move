module supervlabs::test_villain {
    use apto_orm::orm_class;
    use apto_orm::orm_creator;
    use apto_orm::orm_module;
    use apto_orm::orm_object;
    use apto_orm::utilities;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::bcs;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string;

    const CLASS_NAME: vector<u8> = b"TestVillain";
    const ETESTVILLAIN_OBJECT_NOT_FOUND: u64 = 3;
    const ENOT_TESTVILLAIN_OBJECT: u64 = 4;
    const EDEPRECATED_FUNCTION: u64 = 13;

    struct TestVillain has key, copy, drop {
        level: u64,
        created_at: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct TestVillainRg has key, copy, drop {
        level: u64,
        created_at: u64,
    }

    fun init_module(package: &signer) {
        let class_signer = orm_class::create_class_as_collection<TestVillain>(
            package,
            string::utf8(b"TestVillain NFTs"),
            true, true, false, true, false, true, false,
            string::utf8(b"https://nft-metadata.mainnet.aptoslabs.com/cdn/0xf0a7135e062eb06de1978f0bfbf0a8f146e0c56cf94366576aee3cdb7e9858e6.jpeg"),
            string::utf8(b"TestVillain NFTs created by AptoORM"),
            0,
            true,
            true,
            @0x0,
            100,
            1,
        );
        orm_module::set<TestVillain>(
            package,
            signer::address_of(package),
            signer::address_of(&class_signer),
        );
    }

    public fun create_object(
        _user: &signer,
        _name: string::String,
        _uri: string::String,
        _description: string::String,
        _grade: string::String,
        _level: u64,
        _to: Option<address>,
    ): Object<TestVillain>{
        abort(error::invalid_argument(EDEPRECATED_FUNCTION))
    }

    fun create_rg_object(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
        grade: string::String,
        level: u64,
        to: Option<address>,
    ): Object<TestVillainRg>{
        let (orm_creator, orm_class) = orm_module::get<TestVillain>(@supervlabs);
        let creator_signer = orm_creator::load_creator(user, orm_creator);
        let ref = token::create_named_token(
            &creator_signer,
            string::utf8(b"TestVillain NFTs"),
            description,
            utilities::join_str1(
                &string::utf8(b"::"),
                &name,
            ),
            option::none(),
            uri,
        );
        let mutator_ref = token::generate_mutator_ref(&ref);
        token::set_name(&mutator_ref, name);
        orm_object::init_properties(&ref,
            vector[
                string::utf8(b"grade"),
            ],
            vector[
                string::utf8(b"0x1::string::String"),
            ],
            vector[
                bcs::to_bytes<0x1::string::String>(&grade),
            ],
        );
        let object_signer = orm_object::init<TestVillainRg>(&creator_signer, &ref, orm_class);
        let created_at = timestamp::now_seconds();
        move_to<TestVillainRg>(&object_signer, TestVillainRg {
            level: level, created_at: created_at
        });
        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        object::object_from_constructor_ref<TestVillainRg>(&ref)
    }

    public fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
        uri: string::String,
        description: string::String,
        grade: string::String,
        level: u64,
    ) acquires TestVillain, TestVillainRg {
        let object_address = object::object_address(&object);
        assert!(
            exists<TestVillain>(object_address) || exists<TestVillainRg>(object_address),
            error::invalid_argument(ENOT_TESTVILLAIN_OBJECT),
        );
        let object_signer = orm_object::load_signer(user, object);
        orm_object::add_typed_property<T, 0x1::string::String>(
            &object_signer, object, string::utf8(b"grade"), grade,
        );
        if (exists<TestVillain>(object_address)) {
            let user_data = borrow_global_mut<TestVillain>(object_address);
            user_data.level = level;
            user_data.created_at = timestamp::now_seconds();
        } else {
            let user_data = borrow_global_mut<TestVillainRg>(object_address);
            user_data.level = level;
            user_data.created_at = timestamp::now_seconds();
        };
        orm_object::set_uri(user, object, uri);
        orm_object::set_description(user, object, description);
    }

    public fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires TestVillain, TestVillainRg {
        let object_address = object::object_address(&object);
        if (exists<TestVillain>(object_address)) {
            move_from<TestVillain>(object_address);
            orm_object::remove(user, object);
        } else if (exists<TestVillainRg>(object_address)) {
            move_from<TestVillainRg>(object_address);
            orm_object::remove(user, object);
        } else {
            abort(error::invalid_argument(ENOT_TESTVILLAIN_OBJECT))
        };
    }

    entry fun create(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
        grade: string::String,
        level: u64,
    ) {
        create_rg_object(user, name, uri, description, grade, level, option::none());
    }

    entry fun create_to(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
        grade: string::String,
        level: u64,
        to: address,
    ) {
        create_rg_object(user, name, uri, description, grade, level, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
        uri: string::String,
        description: string::String,
        grade: string::String,
        level: u64,
    ) acquires TestVillain, TestVillainRg {
        let obj = object::address_to_object<object::ObjectCore>(object);
        update_object(user, obj, uri, description, grade, level);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires TestVillain, TestVillainRg {
        let obj = object::address_to_object<object::ObjectCore>(object);
        delete_object(user, obj);
    }

    #[view]
    public fun get(object: address): (
        string::String,
        string::String,
        string::String,
        string::String,
        u64,
        u64,
    ) acquires TestVillain, TestVillainRg {
        if (exists<TestVillain>(object)) {
            let o = object::address_to_object<TestVillain>(object);
            let user_data = borrow_global<TestVillain>(object);
            (
                token::name(o),
                token::uri(o),
                token::description(o),
                property_map::read_string(&o, &string::utf8(b"grade")),
                user_data.level,
                user_data.created_at,
            )
        } else {
            let o = object::address_to_object<TestVillainRg>(object);
            let user_data = borrow_global<TestVillainRg>(object);
            (
                token::name(o),
                token::uri(o),
                token::description(o),
                property_map::read_string(&o, &string::utf8(b"grade")),
                user_data.level,
                user_data.created_at,
            )
        }
    }

    #[view]
    public fun exists_at(object: address): bool {
        if (exists<TestVillain>(object)) {
            return true
        };
        exists<TestVillainRg>(object)
    }

    #[test(aptos = @0x1, my_poa = @0x456, user1 = @0x789, user2 = @0xabc, apto_orm = @apto_orm, creator = @package_creator)]
    public entry fun test_modules(
        aptos: &signer, apto_orm: &signer, creator: &signer, my_poa: &signer, user1: &signer, user2: &signer
    ) acquires TestVillain, TestVillainRg {
        use apto_orm::test_utilities;
        use apto_orm::power_of_attorney;
        // use aptos_std::debug;
        // use aptos_framework::timestamp;
        // debug::print<u64>(&timestamp::now_seconds());
        test_utilities::init_network(aptos, 1234);

        let program_address = signer::address_of(apto_orm);
        let creator_address = signer::address_of(creator);
        let my_poa_address = signer::address_of(my_poa);
        let user1_address = signer::address_of(user1);
        let user2_address = signer::address_of(user2);

        test_utilities::create_and_fund_account(program_address, 100);
        test_utilities::create_and_fund_account(creator_address, 10);
        test_utilities::create_and_fund_account(my_poa_address, 100);
        test_utilities::create_and_fund_account(user1_address, 100);
        test_utilities::create_and_fund_account(user2_address, 10);
        let _package_address = orm_creator::get_creator_address(creator_address, string::utf8(b"supervlabs"));
        let package = orm_creator::create_creator(creator, string::utf8(b"supervlabs"));
        init_module(&package);
        power_of_attorney::register_poa(creator, my_poa, 1400, 0);
        let obj1 = create_rg_object(
            my_poa,
            string::utf8(b"villainX #1"),
            string::utf8(b"https://testabc.png.ok"),
            string::utf8(b"Villains Forever description"),
            string::utf8(b"normal"),
            10,
            option::some(user1_address),
        );
        assert!(object::owner(obj1) == user1_address, 1);
        let obj1_address = object::object_address(&obj1);
        let (name, uri, description, grade, level, created_at) = get(obj1_address);
        assert!(name == string::utf8(b"villainX #1"), 1);
        assert!(uri == string::utf8(b"https://testabc.png.ok"), 1);
        assert!(description == string::utf8(b"Villains Forever description"), 1);
        assert!(grade == string::utf8(b"normal"), 1);
        assert!(level == 10, 1);
        assert!(created_at == 1234, 1);
        delete(my_poa, obj1_address);
        assert!(!exists<TestVillainRg>(obj1_address), 1);
    }
}