use starknet::{ContractAddress, contract_address_const};
use core::array::ArrayTrait;
use core::byte_array::ByteArray;
use core::traits::TryInto;
use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
use erc::erc721::{IERC721Dispatcher as NFTDispatcher, IERC721DispatcherTrait as NFTDispatcherTrait};
use snforge_std::{declare, ContractClass, start_cheat_caller_address, stop_cheat_caller_address};

pub mod Accounts {
   use starknet::{ContractAddress, contract_address_const};
   
   pub fn owner() -> ContractAddress {
       contract_address_const::<'OWNER'>()
   }
   
   pub fn caller() -> ContractAddress {
       contract_address_const::<'CALLER'>()
   }
}

fn deploy_contract() -> ContractAddress {
   let contract = declare("ERC721");
   let mut calldata = ArrayTrait::new();
   
   calldata.append(Accounts::owner().into());
   
   let name: ByteArray = "TestNFT".try_into().unwrap();
   let symbol: ByteArray = "TNFT".try_into().unwrap();
   let base_uri: ByteArray = "baseuri/".try_into().unwrap();
   
   calldata.append(name.into());
   calldata.append(symbol.into());
   calldata.append(base_uri.into());
   
   let contract_address = contract.deploy(@calldata).unwrap();
   contract_address
}

#[test]
fn test_successful_mint() {
   let contract_address = deploy_contract();
   let dispatcher = NFTDispatcher { contract_address };
   let recipient = contract_address_const::<'RECIPIENT'>();
   
   start_cheat_caller_address(contract_address, Accounts::owner());
   dispatcher.mint(recipient);
   stop_cheat_caller_address(contract_address);

   let erc721 = IERC721Dispatcher { contract_address };
   assert(erc721.owner_of(1) == recipient, 'Wrong owner');
   assert(erc721.balance_of(recipient) == 1, 'Wrong balance');
}

#[test]
#[should_panic(expected: ('Caller is not the owner',))]
fn test_mint_not_owner() {
   let contract_address = deploy_contract();
   let dispatcher = NFTDispatcher { contract_address };
   let recipient = contract_address_const::<'RECIPIENT'>();
   
   start_cheat_caller_address(contract_address, Accounts::caller());
   dispatcher.mint(recipient);
   stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: ('NFT with id already exists',))]
fn test_mint_duplicate_token() {
   let contract_address = deploy_contract();
   let dispatcher = NFTDispatcher { contract_address };
   let recipient = contract_address_const::<'RECIPIENT'>();
   
   start_cheat_caller_address(contract_address, Accounts::owner());
   dispatcher.mint(recipient);
   dispatcher.mint(recipient);
   stop_cheat_caller_address(contract_address);
}