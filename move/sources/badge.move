module supervlabs::badge {
    use apto_orm::orm_class;
    use apto_orm::orm_creator;
    use apto_orm::orm_module;
    use apto_orm::orm_object;
    use apto_orm::utilities;
    use aptos_framework::object::{Self, Object};
    use aptos_token_objects::token;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string;

    const CLASS_NAME: vector<u8> = b"Badge";
    const EBADGE_OBJECT_NOT_FOUND: u64 = 1;
    const ENOT_BADGE_OBJECT: u64 = 2;
    const EDEPRECATED_FUNCTION: u64 = 10;

    struct Badge has key, copy, drop {
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct BadgeRg has key, copy, drop {
    }

    fun init_module(package: &signer) {
        let class_signer = orm_class::create_class_as_collection<Badge>(
            package,
            string::utf8(b"SuperV Ambassador"),
            true, true, false, true, false, true, false,
            string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/badge/collection.png"),
            string::utf8(b"The Ambassador Badge Collection of Supervillain Idle RPG to promote gaming ecosystem. The SuperV Ambassador badges serve as a beacon of hope and aspiration. Each badge, a unique symbol, encapsulates distinct qualities and energies, designed to harness the positive forces of the universe."),
            0,
            false,
            true,
            @0x0,
            100,
            5,
        );
        orm_module::set<Badge>(
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
        _to: Option<address>,
    ): Object<Badge>{
        abort(error::invalid_argument(EDEPRECATED_FUNCTION))
    }

    fun create_rg_object(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
        to: Option<address>,
    ): Object<BadgeRg>{
        let (orm_creator, orm_class) = orm_module::get<Badge>(@supervlabs);
        let creator_signer = orm_creator::load_creator(user, orm_creator);
        let ref = token::create_named_token(
            &creator_signer,
            string::utf8(b"SuperV Ambassador"),
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
        let object_signer = orm_object::init<BadgeRg>(&creator_signer, &ref, orm_class);
        move_to<BadgeRg>(&object_signer, BadgeRg {
        });
        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        object::object_from_constructor_ref<BadgeRg>(&ref)
    }

    public fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
        uri: string::String,
        description: string::String,
    ) {
        let object_address = object::object_address(&object);
        assert!(
            exists<Badge>(object_address) || exists<BadgeRg>(object_address),
            error::invalid_argument(ENOT_BADGE_OBJECT),
        );
        let _object_signer = orm_object::load_signer(user, object);
        orm_object::set_uri(user, object, uri);
        orm_object::set_description(user, object, description);
    }

    public fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires Badge, BadgeRg {
        let object_address = object::object_address(&object);
        if (exists<Badge>(object_address)) {
            move_from<Badge>(object_address);
            orm_object::remove(user, object);
        } else if (exists<BadgeRg>(object_address)) {
            move_from<BadgeRg>(object_address);
            orm_object::remove(user, object);
        } else {
            abort(error::invalid_argument(ENOT_BADGE_OBJECT))
        }
    }

    entry fun create(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
    ) {
        create_rg_object(user, name, uri, description, option::none());
    }

    entry fun create_to(
        user: &signer,
        name: string::String,
        uri: string::String,
        description: string::String,
        to: address,
    ) {
        create_rg_object(user, name, uri, description, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
        uri: string::String,
        description: string::String,
    ) {
        let obj = object::address_to_object<object::ObjectCore>(object);
        update_object(user, obj, uri, description);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires Badge, BadgeRg {
        let obj = object::address_to_object<object::ObjectCore>(object);
        delete_object(user, obj);
    }

    #[view]
    public fun get(object: address): (
        string::String,
        string::String,
        string::String,
    )  {
        let o = object::address_to_object<object::ObjectCore>(object);
        (
            token::name(o),
            token::uri(o),
            token::description(o),
        )
    }

    #[view]
    public fun exists_at(object: address): bool {
        if (exists<Badge>(object)) {
            return true
        };
        exists<BadgeRg>(object)
    }

    #[test(aptos = @0x1, my_poa = @0x456, user1 = @0x789, user2 = @0xabc, apto_orm = @apto_orm, creator = @package_creator)]
    public entry fun test_modules(
        aptos: &signer, apto_orm: &signer, creator: &signer, my_poa: &signer, user1: &signer, user2: &signer
    ) acquires Badge, BadgeRg {
        use apto_orm::test_utilities;
        use apto_orm::power_of_attorney;
        // use aptos_std::debug;
        // debug::print<String>(&msg);

        test_utilities::init_network(aptos, 10);
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

        power_of_attorney::register_poa(creator, my_poa, 1000, 0);
        let obj1 = create_rg_object(
            my_poa,
            string::utf8(b"badge #1"),
            string::utf8(b"https://testabc.png.ok"),
            string::utf8(b"Villains Forever description"),
            option::some(user1_address),
        );
        assert!(object::owner(obj1) == user1_address, 1);
        let obj1_address = object::object_address(&obj1);
        let (name, uri, description) = get(obj1_address);
        assert!(name == string::utf8(b"badge #1"), 1);
        assert!(uri == string::utf8(b"https://testabc.png.ok"), 1);
        assert!(description == string::utf8(b"Villains Forever description"), 1);
        delete(my_poa, obj1_address);
        assert!(!exists<BadgeRg>(obj1_address), 1);
    }
}