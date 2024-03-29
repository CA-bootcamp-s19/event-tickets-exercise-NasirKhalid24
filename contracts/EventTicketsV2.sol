pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint   PRICE_TICKET = 100 wei;
    address payable public owner;
    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event{
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }
    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier NotOwner {require(msg.sender == owner, "Not the Owner");_;}

    constructor()
        public
    {
        owner = msg.sender;
    }


    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory description, string memory URL, uint tickets)
        public
        NotOwner()
    {
        Event memory e;
        e.description = description;
        e.website = URL;
        e.isOpen = true;
        e.totalTickets = tickets;
        events[idGenerator] = e;
        emit LogEventAdded(e.description, e.website, e.totalTickets, idGenerator);
        idGenerator++;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */     
    function readEvent(uint id)
        view
        public
        returns(string memory, string memory, uint, uint, bool)
    {
        Event memory e = events[id];
        return(e.description, e.website, e.totalTickets, e.sales, e.isOpen);
    }
    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint id, uint t)
        public
        payable
    {
        require(events[id].isOpen == true, "Event closed");
        require(msg.value >= t*PRICE_TICKET, "Enough money sent");
        require(events[id].totalTickets >= events[id].sales + t, "Not enough tickets remaining");
    
        events[id].buyers[msg.sender] += t;
        events[id].sales += t;
        uint _price = t*PRICE_TICKET;
        uint amountToRefund = msg.value - _price;
        msg.sender.transfer(amountToRefund);
        emit LogBuyTickets(msg.sender, id, t);
    }
    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint id)
        public
        payable
    {
        require(events[id].buyers[msg.sender] > 0, "Did not buy any tickets");
        uint tickets_bought = events[id].buyers[msg.sender];
        msg.sender.transfer(tickets_bought*PRICE_TICKET);
        events[id].sales -= tickets_bought;
        events[id].buyers[msg.sender] = 0;
        emit LogGetRefund(msg.sender, id, tickets_bought);
    }
    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint id)
        public
        view
        returns(uint)
    {
        return events[id].buyers[msg.sender];
    }
    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint id)
        public
        NotOwner()
    {
        emit LogEndSale(owner, address(this).balance, id);
        owner.transfer(address(this).balance);
        events[id].isOpen = false;
    }
}
