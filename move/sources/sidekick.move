module supervlabs::sidekick {
    use apto_orm::orm_class;
    use apto_orm::orm_creator;
    use apto_orm::orm_module;
    use apto_orm::orm_object;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;
    use aptos_token_objects::property_map;
    use aptos_token_objects::token;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string;
    use std::vector;

    // use aptos_framework::transaction_context;
    use supervlabs::gacha_rounds;
    use supervlabs::gacha_item;
    use supervlabs::sidekick_capsule;
    use supervlabs::random;

    const CLASS_NAME: vector<u8> = b"Sidekick";
    const ESIDEKICK_OBJECT_NOT_FOUND: u64 = 3;
    const ENOT_SIDEKICK_OBJECT: u64 = 4;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Sidekick has key, drop {
        updated_at: u64,
        salt: u64,
    }

    fun init_module(package: &signer) {
        let class_address = orm_class::update_class_as_collection<Sidekick>(
            package,
            string::utf8(b"SuperV Sidekicks"),
            true, true, false, true, false, true, false,
            string::utf8(b"https://public.vir.supervlabs.io/virweb/nft/sidekicks/collection.png"),
            string::utf8(b"Sidekicks, as faithful allies of the Villains, stand by their side and help maximize the Villains' potential. They typically inhabit the wild before being captured by Villains. By establishing a deep connection, they are reborn as true Sidekicks."),
            0,
            true,
            true,
            @0x0,
            100,
            5,
        );
        orm_module::set<Sidekick>(
            package,
            signer::address_of(package),
            class_address,
        );
        let class_signer = orm_class::load_class_signer(package,
            object::address_to_object<orm_class::OrmClass>(class_address)
        );
        let package_address = signer::address_of(package);
        let grades = vector[
            string::utf8(b"uncommon"),
            string::utf8(b"rare"),
            string::utf8(b"epic"),
            string::utf8(b"legendary"),
        ];
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 200000], 100000000); // 30%, 5%, 0.8%, 0.2%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 20000], 100000000); // 30%, 5%, 0.8%, 0.02%
        gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 10000], 100000000); // 30%, 5%, 0.8%, 0.01%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 5000], 100000000); // 30%, 5%, 0.8%, 0.005%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 2500], 100000000); // 30%, 5%, 0.8%, 0.0025%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 2000], 100000000); // 30%, 5%, 0.8%, 0.002%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 1500], 100000000); // 30%, 5%, 0.8%, 0.0015%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 1000], 100000000); // 30%, 5%, 0.8%, 0.001%
        // gacha_rounds::add(&class_signer, package_address, grades, vector[30000000, 5000000, 800000, 500], 100000000); // 30%, 5%, 0.8%, 0.0005%
    }

    entry fun update_module(user: &signer) {
        let (orm_creator, _orm_class) = orm_module::get<Sidekick>(@supervlabs);
        let package = orm_creator::load_creator(user, orm_creator);
        init_module(&package);
    }

    fun create_object(
        user: &signer,
        sidekick_capsule: address,
        salt: u64,
        to: Option<address>,
    ): Object<Sidekick>{
        let (orm_creator, orm_class) = orm_module::get<Sidekick>(@supervlabs);
        let class_address = object::object_address(&orm_class);
        let creator_signer = orm_creator::load_creator(user, orm_creator);
        let (
            current_round,
            uncommon,
            rare,
            epic,
            legendary,
            denominator,
        ) = gacha_rounds::load_drop_rates_4(class_address);
        // let _txnhash = transaction_context::get_transaction_hash();
        // let _current_time = timestamp::now_microseconds();
        // let roll1 = random::generate_u64(
        //     sidekick_capsule, current_time, salt, txnhash, 0, denominator);
        let (roll1, output1) = random::roll_u64(0, denominator);
        let (group, start_index, end_index, _num) = if (roll1 < legendary) {
            gacha_rounds::round_up(&creator_signer, class_address);
            gacha_item::get_item_group(string::utf8(b"sidekick/legendary"))
        } else if (roll1 < epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/epic"))
        } else if (roll1 < rare + epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/rare"))
        } else if (roll1 < uncommon + rare + epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/uncommon"))
        } else {
            gacha_item::get_item_group(string::utf8(b"sidekick/common"))
        };
        // let roll2 = random::generate_u64(
        //     sidekick_capsule, current_time, salt + 777, txnhash, start_index, end_index);
        let (roll2, output2) = random::roll_u64(start_index, end_index);
        let (name, uri, description, _, property_keys, property_types, property_values) 
            = gacha_item::load_item_data(&creator_signer, group, roll2);
        let ref = token::create(
            &creator_signer,
            string::utf8(b"SuperV Sidekicks"),
            description,
            name, // format: "{ItemName} #{count}"
            option::none(),
            uri,
        );

        let object_signer = orm_object::init<Sidekick>(&creator_signer, &ref, orm_class);
        let object_address = signer::address_of(&object_signer);

        // grade, element
        orm_object::init_properties(&ref,
            property_keys,
            property_types,
            property_values,
        );
        // burn sidekick_capsule
        if (sidekick_capsule != @0x0) {
            let sidekick_capsule_obj = object::address_to_object<sidekick_capsule::SidekickCapsule>(sidekick_capsule);
            sidekick_capsule::delete_object(user, sidekick_capsule_obj);
        };
        let updated_at = timestamp::now_seconds();
        move_to<Sidekick>(&object_signer, Sidekick {
            updated_at: updated_at, salt: salt
        });
        let obj = object::address_to_object<Sidekick>(object_address);
        orm_object::add_typed_property<Sidekick, address>(
            user, obj, string::utf8(b"sidekick_capsule"), sidekick_capsule,
        );
        gacha_rounds::set_round_log(class_address, &ref, current_round);
        // random::store(&object_signer, sidekick_capsule, current_time, salt, txnhash, 0, denominator);
        // random::store(&object_signer, sidekick_capsule, current_time, salt + 777, txnhash, start_index, end_index);

        random::store_roll_u64(&object_signer, output1);
        random::store_roll_u64(&object_signer, output2);

        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        object::object_from_constructor_ref<Sidekick>(&ref)
    }

    fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires Sidekick {
        let object_address = object::object_address(&object);
        assert!(
            exists<Sidekick>(object_address),
            error::invalid_argument(ENOT_SIDEKICK_OBJECT),
        );
        let _object_signer = orm_object::load_signer(user, object);
        let user_data = borrow_global_mut<Sidekick>(object_address);
        user_data.updated_at = timestamp::now_seconds();
    }

    fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires Sidekick {
        let object_address = object::object_address(&object);
        assert!(
          exists<Sidekick>(object_address),
          error::invalid_argument(ENOT_SIDEKICK_OBJECT),
        );
        move_from<Sidekick>(object_address);
        orm_object::remove(user, object);
    }

    entry fun create(
        user: &signer,
        sidekick_capsule: address,
        salt: u64,
    ) {
        create_object(user, sidekick_capsule, salt, option::none());
    }

    entry fun create_to(
        user: &signer,
        sidekick_capsule: address,
        salt: u64,
        to: address,
    ) {
        create_object(user, sidekick_capsule, salt, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
    ) acquires Sidekick {
        let obj = object::address_to_object<Sidekick>(object);
        update_object(user, obj);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires Sidekick {
        let obj = object::address_to_object<Sidekick>(object);
        delete_object(user, obj);
    }

    #[view]
    public fun get(object: address): (
        string::String,
        string::String,
        string::String,
        address,
        u64,
        u64,
    ) acquires Sidekick {
        let o = object::address_to_object<Sidekick>(object);
        let user_data = borrow_global<Sidekick>(object);
        (
            token::name(o),
            token::uri(o),
            token::description(o),
            property_map::read_address(&o, &string::utf8(b"sidekick_capsule")),
            user_data.updated_at,
            user_data.salt,
        )
    }

    #[view]
    public fun exists_at(object: address): bool {
        exists<Sidekick>(object)
    }

    #[view]
    public fun replay_to_create_object(object: address): (
        string::String, u64, u64, u64, u64, u64, u64, u64, u64, string::String, u64, u64,
    ) {
        let (_orm_creator, orm_class) = orm_module::get<Sidekick>(@supervlabs);
        let class_address = object::object_address(&orm_class);
        let (
            current_round, _selected_round,
            numerators, denominator, _updated_at
        ) = gacha_rounds::get_round_log_with_drop_rates(class_address, object);
        // let (_rand_inputs, rand_results) = random::replay_generated_u64(object);
        let rand_results = random::replay_roll_u64(object);
        let roll1 = *vector::borrow(&rand_results, 0);
        let roll2 = *vector::borrow(&rand_results, 1);
        let legendary = *vector::borrow(&numerators, 3);
        let epic = *vector::borrow(&numerators, 2);
        let rare = *vector::borrow(&numerators, 1);
        let uncommon = *vector::borrow(&numerators, 0);
        let (group, start_index, end_index, _num) = if (roll1 < legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/legendary"))
        } else if (roll1 < epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/epic"))
        } else if (roll1 < rare + epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/rare"))
        } else if (roll1 < uncommon + rare + epic + legendary) {
            gacha_item::get_item_group(string::utf8(b"sidekick/uncommon"))
        } else {
            gacha_item::get_item_group(string::utf8(b"sidekick/common"))
        };
        let (_, _, _name, _uri, _description, _, _property_keys, _property_types, _property_values)
            = gacha_item::get_by_index(group, roll2);
        let o = object::address_to_object<Sidekick>(object);
        (
            token::name(o),
            roll1,
            roll2,
            current_round,
            legendary,
            epic + legendary,
            rare + epic + legendary,
            uncommon + rare + epic + legendary,
            denominator,
            group,
            start_index,
            end_index,
        )
    }
}