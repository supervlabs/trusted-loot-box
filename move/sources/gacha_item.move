module supervlabs::gacha_item {
    use apto_orm::orm_class;
    use apto_orm::orm_creator;
    use apto_orm::orm_module;
    use apto_orm::orm_object;
    use apto_orm::utilities;
    use aptos_framework::object::{Self, Object};
    use aptos_framework::timestamp;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string;

    const CLASS_NAME: vector<u8> = b"GachaItem";
    const EGACHAITEMGROUP_OBJECT_NOT_FOUND: u64 = 2;
    const EGACHAITEM_OBJECT_NOT_FOUND: u64 = 3;
    const ENOT_GACHAITEM_OBJECT: u64 = 4;
    const EINDEX_NOT_IN_ORDER: u64 = 5;
    const ENOT_AUTHORIZED_OWNER: u64 = 6;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GachaItem has key, drop {
        group: string::String,
        index: u64,
        name: string::String,
        uri: string::String,
        description: string::String,
        updated_at: u64,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GachaItemCount has key, drop {
        count: u64,
    }

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct GachaItemGroup has key, drop {
        group: string::String,
        start_index: u64,
        end_index: u64,
        num: u64,
    }

    fun init_module(package: &signer) {
        let class_signer = orm_class::create_class_as_object<GachaItem>(
            package,
            string::utf8(CLASS_NAME),
            true, true, false, true, false, true, false
        );
        orm_module::set<GachaItem>(
            package,
            signer::address_of(package),
            signer::address_of(&class_signer),
        );
    }

    fun create_object(
        user: &signer,
        group: string::String,
        index: u64,
        name: string::String,
        uri: string::String,
        description: string::String,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
        to: Option<address>,
    ): Object<GachaItem> acquires GachaItemGroup {
        let (orm_creator, orm_class) = orm_module::get<GachaItem>(@supervlabs);
        let creator_signer = orm_creator::load_creator(user, orm_creator);

        // create or update group
        let group_obj_seed = *string::bytes(&group);
        let creator_address = signer::address_of(&creator_signer);
        let group_obj_address = object::create_object_address(&creator_address, group_obj_seed);
        if (exists<GachaItemGroup>(group_obj_address)) {
            let item_group = borrow_global_mut<GachaItemGroup>(group_obj_address);
            if (index < item_group.start_index) {
                assert!(index == item_group.start_index - 1, error::invalid_argument(EINDEX_NOT_IN_ORDER));
                item_group.start_index = index;
            } else if (index >= item_group.end_index) {
                assert!(index == item_group.end_index, error::invalid_argument(EINDEX_NOT_IN_ORDER));
                item_group.end_index = index + 1;
            };
            item_group.num = item_group.num + 1;
        } else {
            let ref = object::create_named_object(&creator_signer, group_obj_seed);
            let group_signer = object::generate_signer(&ref);
            let item_group = GachaItemGroup {
                group: group,
                start_index: index,
                end_index: index + 1,
                num: 1,
            };
            move_to<GachaItemGroup>(&group_signer, item_group);
        };

        // create new object for gacha_item
        let objname = utilities::join_str2(
            &string::utf8(b"::"),
            &group,
            &aptos_std::string_utils::to_string(&index),
        );
        let ref = object::create_named_object(
            &creator_signer,
            *string::bytes(&objname),
        );
        let object_signer = orm_object::init<GachaItem>(&creator_signer, &ref, orm_class);
        let updated_at = timestamp::now_seconds();
        move_to<GachaItem>(&object_signer, GachaItem {
            group: group, index: index, name: name, uri: uri, description: description, updated_at: updated_at, property_keys: property_keys, property_types: property_types, property_values: property_values
        });
        move_to<GachaItemCount>(&object_signer, GachaItemCount { count: 0 });
        if (option::is_some(&to)) {
            let destination = option::extract<address>(&mut to);
            orm_object::transfer_initially(&ref, destination);
        };
        object::object_from_constructor_ref<GachaItem>(&ref)
    }

    fun update_object<T: key>(
        user: &signer,
        object: Object<T>,
        name: string::String,
        uri: string::String,
        description: string::String,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
    ) acquires GachaItem {
        let object_address = object::object_address(&object);
        assert!(
            exists<GachaItem>(object_address),
            error::invalid_argument(ENOT_GACHAITEM_OBJECT),
        );
        let object_signer = orm_object::load_signer(user, object);
        let user_data = borrow_global_mut<GachaItem>(object_address);
        user_data.name = name;
        user_data.uri = uri;
        user_data.description = description;
        user_data.updated_at = timestamp::now_seconds();
        user_data.property_keys = property_keys;
        user_data.property_types = property_types;
        user_data.property_values = property_values;
        if (!exists<GachaItemCount>(object_address)) {
            move_to<GachaItemCount>(&object_signer, GachaItemCount { count: 0 });
        };
    }

    fun delete_object<T: key>(
        user: &signer,
        object: Object<T>,
    ) acquires GachaItem, GachaItemGroup, GachaItemCount {
        let object_address = object::object_address(&object);
        assert!(
          exists<GachaItem>(object_address),
          error::invalid_argument(ENOT_GACHAITEM_OBJECT),
        );
        let (orm_creator, _) = orm_module::get<GachaItem>(@supervlabs);
        let item = move_from<GachaItem>(object_address);
        let group_obj_seed = *string::bytes(&item.group);
        let creator_address = object::object_address(&orm_creator);
        let group_obj_address = object::create_object_address(&creator_address, group_obj_seed);
        assert!(
            exists<GachaItemGroup>(group_obj_address),
            error::invalid_argument(EGACHAITEMGROUP_OBJECT_NOT_FOUND),
        );
        let item_group = borrow_global_mut<GachaItemGroup>(group_obj_address);
        item_group.num = item_group.num - 1;
        if (item_group.start_index == item.index) {
            item_group.start_index = item_group.start_index + 1;
        } else if (item_group.end_index == item.index + 1) {
            item_group.end_index = item_group.end_index - 1;
        } else {
            abort(error::invalid_argument(EINDEX_NOT_IN_ORDER))
        };
        if (exists<GachaItemCount>(object_address)) {
            move_from<GachaItemCount>(object_address);
        };
        orm_object::remove(user, object);
    }

    entry fun create(
        user: &signer,
        group: string::String,
        index: u64,
        name: string::String,
        uri: string::String,
        description: string::String,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
    ) acquires GachaItemGroup {
        create_object(user, group, index, name, uri, description, property_keys, property_types, property_values, option::none());
    }

    entry fun create_to(
        user: &signer,
        group: string::String,
        index: u64,
        name: string::String,
        uri: string::String,
        description: string::String,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
        to: address,
    ) acquires GachaItemGroup {
        create_object(user, group, index, name, uri, description, property_keys, property_types, property_values, option::some(to));
    }

    entry fun update(
        user: &signer,
        object: address,
        name: string::String,
        uri: string::String,
        description: string::String,
        property_keys: vector<string::String>,
        property_types: vector<string::String>,
        property_values: vector<vector<u8>>,
    ) acquires GachaItem {
        let obj = object::address_to_object<GachaItem>(object);
        update_object(user, obj, name, uri, description, property_keys, property_types, property_values);
    }

    entry fun delete(
        user: &signer,
        object: address,
    ) acquires GachaItem, GachaItemGroup, GachaItemCount {
        let obj = object::address_to_object<GachaItem>(object);
        delete_object(user, obj);
    }

    public fun count(owner: &signer, item_obj: address): u64 acquires GachaItemCount {
        let obj = object::address_to_object<GachaItem>(item_obj);
        assert!(
            object::owner(obj) == signer::address_of(owner),
            error::invalid_argument(ENOT_AUTHORIZED_OWNER),
        );
        let item_count = borrow_global_mut<GachaItemCount>(item_obj);
        item_count.count = item_count.count + 1;
        item_count.count
    }

    public fun load_item_data(owner: &signer, group: string::String, index: u64): (
        string::String,
        string::String,
        string::String,
        u64,
        vector<string::String>,
        vector<string::String>,
        vector<vector<u8>>,
    ) acquires GachaItem, GachaItemCount {
        let obj_address = get_address(group, index);
        let obj = object::address_to_object<GachaItem>(obj_address);
        assert!(
            object::owner(obj) == signer::address_of(owner),
            error::invalid_argument(ENOT_AUTHORIZED_OWNER),
        );
        let item_data = borrow_global<GachaItem>(obj_address);
        let item_count = borrow_global_mut<GachaItemCount>(obj_address);
        item_count.count = item_count.count + 1;
        let name = item_data.name;
        string::append(&mut name, string::utf8(b" #"));
        string::append(&mut name, aptos_std::string_utils::to_string(&item_count.count));
        (
            name,
            item_data.uri,
            item_data.description,
            item_data.updated_at,
            item_data.property_keys,
            item_data.property_types,
            item_data.property_values,
        )
    }

    #[view]
    public fun get_address(group: string::String, index: u64): address {
        let (orm_creator, _) = orm_module::get<GachaItem>(@supervlabs);
        let creator_address = object::object_address(&orm_creator);
        let objname = utilities::join_str2(
            &string::utf8(b"::"),
            &group,
            &aptos_std::string_utils::to_string(&index),
        );
        object::create_object_address(&creator_address, *string::bytes(&objname))
    }

    #[view]
    public fun get(object: address): (
        string::String,
        u64,
        string::String,
        string::String,
        string::String,
        u64,
        vector<string::String>,
        vector<string::String>,
        vector<vector<u8>>,
    ) acquires GachaItem {
        let _o = object::address_to_object<GachaItem>(object);
        let user_data = borrow_global<GachaItem>(object);
        (
            user_data.group,
            user_data.index,
            user_data.name,
            user_data.uri,
            user_data.description,
            user_data.updated_at,
            user_data.property_keys,
            user_data.property_types,
            user_data.property_values,
        )
    }

    #[view]
    public fun exists_at(object: address): bool {
        exists<GachaItem>(object)
    }

    #[view]
    public fun get_by_index(group: string::String, index: u64): (
        string::String,
        u64,
        string::String,
        string::String,
        string::String,
        u64,
        vector<string::String>,
        vector<string::String>,
        vector<vector<u8>>,
    ) acquires GachaItem {
        let (orm_creator, _) = orm_module::get<GachaItem>(@supervlabs);
        let creator_address = object::object_address(&orm_creator);
        let objname = utilities::join_str2(
            &string::utf8(b"::"),
            &group,
            &aptos_std::string_utils::to_string(&index),
        );
        let object_address = object::create_object_address(
            &creator_address, *string::bytes(&objname));
        get(object_address)
    }

    #[view]
    public fun get_item_group(group: string::String): (
        string::String,
        u64,
        u64,
        u64,
    ) acquires GachaItemGroup {
        let (orm_creator, _) = orm_module::get<GachaItem>(@supervlabs);
        let creator_address = object::object_address(&orm_creator);
        let group_obj_seed = *string::bytes(&group);
        let group_obj_address = object::create_object_address(&creator_address, group_obj_seed);
        assert!(
            exists<GachaItemGroup>(group_obj_address),
            error::invalid_argument(EGACHAITEMGROUP_OBJECT_NOT_FOUND),
        );
        let user_data = borrow_global<GachaItemGroup>(group_obj_address);
        (
            user_data.group,
            user_data.start_index,
            user_data.end_index,
            user_data.num,
        )
    }
}