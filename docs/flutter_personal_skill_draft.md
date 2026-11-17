


<!-- state maangement tips -->
<!-- 1.use bloc as statemmanagement
     2.use equatable and const constructure in state classes for avoiding duplicate state
     3.use sealed classes for state to handle different cases to utilize power of exhaustive compile time checking later
     4.Wherever possible in bloc builder or bloc consumer, use switch case to handle all state via exhaustive check of sealed state
     5. Leverage Atomic State Class and Selective State updates as much as possible. Utilize copywith constructor and immutable data structures for atomic state. Use Bloc selector for Sective State Updates of selective properties whereever required. to avoid rebuilds due to other properties change.
     6.Utilize judicious use of Bloc Listner Navigation, dialogs and snackbars and other UI related side effects and reactive programming. dont unncessariliy use bloc consumer everywhere
     7.Use Bloc to bloc communication with Bloc Listner , if needed to.
     8. Use Event transformers to handle debouncing, distinct until changed etc. whereever needed.
     9.Keep Bloc instantiation lazy true untill required to make it false as per usecase.
     10. Use Bloc Observer.
     11. Try to keep bloc as pure function of state and events as much as possible.  
     12. Try handle state management so that rebuilds are not much and are selective. and optimized
     13.



     Navigation and routing
     1.Use go router and  Keep seperate file for route string, actual routes, and route resolver
     2. use nested routing and declarative navigation
     3. pass params and extra data properly
     4.  handle deep links if needed
     5.handle auth guard
     6.handle loading and error states properly
     7.handle preloading if needed



     API and Networking Best Practices
     1. Use Interceptors for request and response manipulation and error handling.
     2. Use Dio or http with interceptors for API calls and Error handling
     3. Use json_serializable for data modeling
     4. Use Repository pattern for data abstraction
     5. Use Repository factory or GetIt for dependency injection
     6. Use try catch with proper error handling and meaningful error messages
     7. Use proper status code based error handling
     8. Use proper retry mechanism
     9. Use proper caching mechanism if needed
     10. Use proper timeout mechanism if needed
     11. Use proper request cancellation mechanism if needed
     12. Use proper request batching mechanism if needed
     13. Use proper request throttling mechanism if needed
     14. Use proper request queueing mechanism if needed







 -->