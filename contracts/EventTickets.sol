pragma solidity ^0.5.0;

    /*
        The EventTickets contract keeps track of the details and ticket sales of one event.
     */

contract EventTickets {

    /*
        Create a public state variable called owner.
        Use the appropriate keyword to create an associated getter function.
        Use the appropriate keyword to allow ether transfers.
     */

    uint   TICKET_PRICE = 100 wei;
    address payable public owner;

    /*
        Create a struct called "Event".
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
    Event myEvent;

    /*
        Define 3 logging events.
        LogBuyTickets should provide information about the purchaser and the number of tickets purchased.
        LogGetRefund should provide information about the refund requester and the number of tickets refunded.
        LogEndSale should provide infromation about the contract owner and the balance transferred to them.
    */

    event LogBuyTickets(address purchaser, uint number_of_tickets);
    event LogGetRefund(address requester, uint number_of_tickets_refunded);
    event LogEndSale(address owner, uint balance_transferred);
    
    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier NotOwner {require(msg.sender == owner, "Not the Owner");_;}
    
    /*
        Define a constructor.
        The constructor takes 3 arguments, the description, the URL and the number of tickets for sale.
        Set the owner to the creator of the contract.
        Set the appropriate myEvent details.
    */
    constructor(string memory description, string memory URL, uint tickets)
        public
    {
        owner = msg.sender;
        myEvent.description = description;
        myEvent.website = URL;
        myEvent.totalTickets = tickets;
        myEvent.isOpen = true;
    }
    /*
        Define a funciton called readEvent() that returns the event details.
        This function does not modify state, add the appropriate keyword.
        The returned details should be called description, website, uint totalTickets, uint sales, bool isOpen in that order.
    */
    function readEvent() 
        view
        public 
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) 
    {
        description = myEvent.description;
        website = myEvent.website;
        totalTickets = myEvent.totalTickets;
        sales = myEvent.sales;
        isOpen = myEvent.isOpen;
    }

    /*
        Define a function called getBuyerTicketCount().
        This function takes 1 argument, an address and
        returns the number of tickets that address has purchased.
    */
    function getBuyerTicketCount(address a)
        public
        view
        returns(uint)
    {
        return myEvent.buyers[a];
    }

    /*
        Define a function called buyTickets().
        This function allows someone to purchase tickets for the event.
        This function takes one argument, the number of tickets to be purchased.
        This function can accept Ether.
        Be sure to check:
            - That the event isOpen
            - That the transaction value is sufficient for the number of tickets purchased
            - That there are enough tickets in stock
        Then:
            - add the appropriate number of tickets to the purchasers count
            - account for the purchase in the remaining number of available tickets
            - refund any surplus value sent with the transaction
            - emit the appropriate event
    */
    function buyTickets(uint tickets_to_buy)
        public
        payable
    {
        require(myEvent.isOpen == true, "Event is closed");
        require(msg.value >= tickets_to_buy*TICKET_PRICE, "Not enough funds sent");
        require(myEvent.totalTickets >= myEvent.sales + tickets_to_buy, "Not enough tickets remaining");

        myEvent.buyers[msg.sender] += tickets_to_buy;
        myEvent.sales += tickets_to_buy;
        uint _price = tickets_to_buy*TICKET_PRICE;
        uint amountToRefund = msg.value - _price;
        msg.sender.transfer(amountToRefund);
        emit LogBuyTickets(msg.sender, tickets_to_buy);
    }
    /*
        Define a function called getRefund().
        This function allows someone to get a refund for tickets for the account they purchased from.
        TODO:
            - Check that the requester has purchased tickets.
            - Make sure the refunded tickets go back into the pool of avialable tickets.
            - Transfer the appropriate amount to the refund requester.
            - Emit the appropriate event.
    */
    function getRefund()
        public
        payable
    {
        require(myEvent.buyers[msg.sender] > 0, "Did not buy any tickets");
        uint tickets_bought = myEvent.buyers[msg.sender];
        msg.sender.transfer(tickets_bought*TICKET_PRICE);
        myEvent.sales -= tickets_bought;
        myEvent.buyers[msg.sender] = 0;
        emit LogGetRefund(msg.sender, tickets_bought);
    }
    /*
        Define a function called endSale().
        This function will close the ticket sales.
        This function can only be called by the contract owner.
        TODO:
            - close the event
            - transfer the contract balance to the owner
            - emit the appropriate event
    */
    function endSale()
        public
        NotOwner()
    {
        emit LogEndSale(owner, address(this).balance);
        owner.transfer(address(this).balance);
        myEvent.isOpen = false;
    }
}