module supervlabs::svl_inventory {
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
    use std::aptos_account;

    const CLASS_NAME: vector<u8> = b"SvlInventory";
    const ESVLINVENTORY_OBJECT_NOT_FOUND: u64 = 1;
    const ENOT_SVLINVENTORY_OBJECT: u64 = 2;
    const EDEPRECATED_FUNCTION: u64 = 13;

    struct SvlInventory has key, copy, drop {
        id: string::String,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct SvlInventoryRg has key, copy, drop {
        id: string::String,
    }

    fun init_module(package: &signer) {
        let class_signer = orm_class::create_class_as_collection<SvlInventory>(
            package,
            string::utf8(b"Super Villains Inventory"),
            true, true, false, true, false, true, false,
            string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/Inventory.png"),
            string::utf8(b"Super Villains' AptoORM Token Inventory to hold all assets used in Games"),
            0,
            false,
            false,
            @0x0,
            100,
            3,
        );
        orm_module::set<SvlInventory>(
            package,
            signer::address_of(package),
            signer::address_of(&class_signer),
        );
    }

    public fun create_object(
        _user: &signer,
        _id: string::String,
        _to: Option<address>,
    ): Object<SvlInventory>{
        abort(error::invalid_argument(EDEPRECATED_FUNCTION))
    }

    fun create_rg_object(
        user: &signer,
        id: string::String,
        to: Option<address>,
    ): Object<SvlInventoryRg>{
        let (orm_creator, orm_class) = orm_module::get<SvlInventory>(@supervlabs);
        let creator_signer = orm_creator::load_creator(user, orm_creator);
        let name = string::utf8(b"SvlInventory");
        let uri = string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/Inventory.png");
        let description = string::utf8(b"Super Villains' AptoORM Token Inventory to hold all assets used in Games");
        let ref = token::create_named_token(
            &creator_signer,
            string::utf8(b"Super Villains Inventory"),
            description,
            utilities::join_str2(
                &string::utf8(b"::"),
                &name,
                &id,
            ),
            option::none(),
            uri,
        );
        let mutator_ref = token::generate_mutator_ref(&ref);
        token::set_name(&mutator_ref, name);
        let object_signer = orm_object::init<SvlInventoryRg>(&creator_signer, &ref, orm_class);
        move_to<SvlInventoryRg>(&object_signer, SvlInventoryRg {
            id: id
        });
        aptos_account::transfer(user, signer::address_of(&object_signer), 0);
        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        object::object_from_constructor_ref<SvlInventoryRg>(&ref)
    }

    public fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) {
        let object_address = object::object_address(&object);
        assert!(
            exists<SvlInventory>(object_address) || exists<SvlInventoryRg>(object_address),
            error::invalid_argument(ENOT_SVLINVENTORY_OBJECT),
        );
        let _object_signer = orm_object::load_signer(user, object);
    }

    public fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires SvlInventory, SvlInventoryRg {
        let object_address = object::object_address(&object);
        if (exists<SvlInventory>(object_address)) {
            move_from<SvlInventory>(object_address);
            orm_object::remove(user, object);
        } else if (exists<SvlInventoryRg>(object_address)) {
            move_from<SvlInventoryRg>(object_address);
            orm_object::remove(user, object);
        } else {
            abort(error::invalid_argument(ENOT_SVLINVENTORY_OBJECT))
        }
    }

    entry fun create(
        user: &signer,
        id: string::String,
    ) {
        create_rg_object(user, id, option::none());
    }

    entry fun create_to(
        user: &signer,
        id: string::String,
        to: address,
    ) {
        create_rg_object(user, id, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
    ) {
        let obj = object::address_to_object<object::ObjectCore>(object);
        update_object(user, obj);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires SvlInventory, SvlInventoryRg {
        let obj = object::address_to_object<object::ObjectCore>(object);
        delete_object(user, obj);
    }

    #[view]
    public fun get(object: address): (
        string::String,
        string::String,
        string::String,
        string::String,
    ) acquires SvlInventory, SvlInventoryRg {
        if (exists<SvlInventoryRg>(object)) {
            let o = object::address_to_object<SvlInventoryRg>(object);
            let user_data = borrow_global<SvlInventoryRg>(object);
            (
                token::name(o),
                user_data.id,
                token::uri(o),
                token::description(o),
            )
        } else {
            let o = object::address_to_object<SvlInventory>(object);
            let user_data = borrow_global<SvlInventory>(object);
            (
                token::name(o),
                user_data.id,
                token::uri(o),
                token::description(o),
            )
        }
    }

    #[view]
    public fun exists_at(object: address): bool {
        if (exists<SvlInventory>(object)) {
            return true
        };
        exists<SvlInventoryRg>(object)
    }

    #[test(aptos = @0x1, my_poa = @0x456, user1 = @0x789, user2 = @0xabc, apto_orm = @apto_orm, creator = @package_creator)]
    public entry fun test_modules(
        aptos: &signer, apto_orm: &signer, creator: &signer, my_poa: &signer, user1: &signer, user2: &signer
    ) acquires SvlInventory, SvlInventoryRg {
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
            string::utf8(b"supervlabs member #1"),
            option::some(user1_address),
        );
        assert!(object::owner(obj1) == user1_address, 1);
        assert!(token::name(obj1) == string::utf8(b"SvlInventory"), 1);
        assert!(token::description(obj1) == string::utf8(b"Super Villains' AptoORM Token Inventory to hold all assets used in Games"), 1);
        let obj1_address = object::object_address(&obj1);
        let (name, id, uri, description) = get(obj1_address);
        assert!(name == string::utf8(b"SvlInventory"), 1);
        assert!(id == string::utf8(b"supervlabs member #1"), 1);
        assert!(uri == string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/Inventory.png"), 1);
        assert!(description == string::utf8(b"Super Villains' AptoORM Token Inventory to hold all assets used in Games"), 1);
        delete(my_poa, obj1_address);
        assert!(!exists<SvlInventoryRg>(obj1_address), 1);
    }
}