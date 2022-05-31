import IC "./ic";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import TrieSet "mo:base/TrieSet";
import TrieMap "mo:base/TrieMap";
import Array "mo:base/Array";

shared (install) actor class Test(m_: Nat, members_: [Principal]) = self {
  var Info = {
    not_member: Text = "Caller not belongs members!";
    ok: Text = "OK!";
    not_exist: Text = "Proposol not exists!";
  };

  stable var M = m_;
  stable var N = members_.size();
  stable var members = TrieSet.fromArray<Principal>(members_, Principal.hash, Principal.equal);
  // two type of proposols: 
  // give: give permission to a canister
  // remove: remove permission of a canister

  stable var pid = 0;
  var giveProposols = TrieMap.TrieMap<Principal, Nat>(Principal.equal, Principal.hash);
  var removeProposols = TrieMap.TrieMap<Principal, Nat>(Principal.equal, Principal.hash);
  stable var results: [TrieSet.Set<Principal>] = [];

  public shared({caller}) func raise_giveProposal(proposal: Principal): async Text {
    if(not TrieSet.mem(members, caller, Principal.hash(caller), Principal.equal)) {
      return Info.not_member;
    };
    switch (giveProposols.get(proposal)) {
      case null {
        giveProposols.put(proposal, pid);
      };
      case (?id) {
        giveProposols.delete(proposal);
        giveProposols.put(proposal, pid);
      };
    };
    results := Array.append<TrieSet.Set<Principal>>(results, [TrieSet.empty<Principal>()]);
    pid += 1;
    return Info.ok;      
  };

  public shared({caller}) func raise_removeProposal(proposal: Principal): async Text {
    if(not TrieSet.mem(members, caller, Principal.hash(caller), Principal.equal)) {
      return Info.not_member;
    };
    switch (removeProposols.get(proposal)) {
      case null {
        removeProposols.put(proposal, pid);
      };
      case (?id) {
        removeProposols.delete(proposal);
        removeProposols.put(proposal, pid);
      };
    };
    results := Array.append<TrieSet.Set<Principal>>(results, [TrieSet.empty<Principal>()]);
    pid += 1;
    return Info.ok;      
  };

  public shared({caller}) func vote_giveProposal(proposal: Principal, vote: Bool): async Text {
    if(not TrieSet.mem(members, caller, Principal.hash(caller), Principal.equal)) {
      return Info.not_member;
    };
    switch (giveProposols.get(proposal)) {
      case null {
        return Info.not_exist;
      };
      case (?id) {
        //TODO： 如何动态修改数组中的集合？
        ignore TrieSet.put<Principal>(results[id], proposal, Principal.hash(proposal), Principal.equal);
        return Info.ok;
      };
    };        
  };

  public shared({caller}) func vote_removeProposal(proposal: Principal, vote: Bool): async Text {
    if(not TrieSet.mem(members, caller, Principal.hash(caller), Principal.equal)) {
      return Info.not_member;
    };
     switch (removeProposols.get(proposal)) {
      case null {
        return Info.not_exist;
      };
      case (?id) {
        //TODO：
        ignore TrieSet.put<Principal>(results[id], proposal, Principal.hash(proposal), Principal.equal);
        return Info.ok;
      };
    };        
  };

  //判断是否有权限
  //如果giveProposols和removeProposols的投票结果均生效，那么取pid更大的那一个
  public shared({caller}) func has_permission(proposal: Principal): async Bool {
    if(not TrieSet.mem(members, caller, Principal.hash(caller), Principal.equal)) {
      return false;
    };
    switch (giveProposols.get(proposal)) {
      case null {
        return false;
      };
      case (?giveId) {
        if (TrieSet.size<Principal>(results[giveId]) < M) {return false};
        switch (removeProposols.get(proposal)) {
          case null {
            return true;
          };
          case (?removeId) {
            if (TrieSet.size<Principal>(results[removeId]) < M) {return true};
            return giveId > removeId;
          };
        };
      };
    };    
  };

  public func create_canister(): async IC.canister_id {
    let settings = {
      freezing_threshold = null;
      controllers = ?[Principal.fromActor(self)];
      memory_allocation = null;
      compute_allocation = null;
    };
    let ic: IC.Self = actor("aaaaa-aa");
    let result = await ic.create_canister({settings = ?settings});
    result.canister_id
  };

  public func start_canister(id: Principal) {
    let state = await has_permission(id);
    if (state) {
      let ic: IC.Self = actor("aaaaa-aa");
      await ic.start_canister({canister_id=id});
    }
  };

  public func stop_canister(id: Principal) {
    let state = await has_permission(id);
    if (state) {
       let ic: IC.Self = actor("aaaaa-aa");
       await ic.stop_canister({canister_id=id});
    }
  };

  public func delete_canister(id: Principal) {
    let state = await has_permission(id);
    if (state) {
      let ic: IC.Self = actor("aaaaa-aa");
      await ic.delete_canister({canister_id=id});
    }
  };

  public func install_code(arg: [Nat8], 
                           wasm_module: [Nat8], 
                           mode: { #reinstall; #upgrade; #install },
                           canister_id: Principal) {
    let state = await has_permission(canister_id);
    if (state) {
      let ic: IC.Self = actor("aaaaa-aa");
      await ic.install_code({arg=arg; wasm_module=wasm_module; mode=mode; canister_id=canister_id});
    }
  };
};
