// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; //Stating our version

contract SimpleStorage {
    //class like

    // uint256 favoriteNumber=88; //variable unit=integer

    // every variable is intialized to 0 if no value is given
    uint256 public myFavoriteNumber; //0 (storage variable)

    // a function that modifies the variable myfavorite number
    function store(uint256 _favoriteNumber) public virtual {
        //virtual is used to make the contract applicable for override
        myFavoriteNumber = _favoriteNumber;
    }

    // view,pure only reads the function and cannot modify the fucntion like store or disallow updating state
    function retrieve() public view returns (uint256) {
        return myFavoriteNumber;
    }

    // type like in typescript
    struct Person {
        //person type takes 2 variable
        uint256 favoriteNumber;
        string name;
    }

    // a variable named Pat
    // Person public Pat=Person({favoriteNumber:7,name:"Patrick"});

    // A person array with visibilty of public named listOfPeople (dynamic array)
    Person[] public listOfPeople;

    // static array with total size of 3
    // Person[3] public listOfPeople;

    //used to map the variable with its value
    mapping(string => uint256) public nameToFavoriteNumber;

    // function to add people

    //memory,calldata,storage are used to store the data
    // memory and calldata are used to temporarily store the data
    // in memory the data stored can be manipulated/ changedd but in calldata the data cannot be manipulated

    function addPeople(string memory _name, uint256 _favoriteNumber) public {
        // _name="cat"; //works in memory but not in calldata
        listOfPeople.push(Person(_favoriteNumber, _name));
        nameToFavoriteNumber[_name] = _favoriteNumber; //mapping
    }
}

// if transaction is made after button deploy is yellow else its blue or function is yellow
