/**************************************************************************** 
 * Written by Justin Stevens and Matt Gallivan 
 * Compile as
 * mex mexAstar.cpp
 ****************************************************************************/

#include "mex.h"
#include "./priority_tree.h"

using namespace std;

/********************************************************
 * The heap data structure used for A* search
 * Justin Stevens
 * June 1, 2021
 ********************************************************/

class NodeValue{
    public: 
        // Two member variables: f cost and the current node
        double f;
        i64 g; 
        i64 node; 
        i64 timeE; 

        NodeValue(double f1, i64 g1, i64 node1, i64 time1){
            f = f1;
            g = g1; 
            node = node1;
            timeE = time1; 
        }
        // Comparison between two nodes for use in our priority queue 
        friend bool operator < ( const NodeValue& first, const NodeValue& second);
};

bool operator < (const NodeValue& first, const NodeValue& second){
    // Returns true if we expand the second node before the first node 
    // If the two f-values are the same, sort by the *higher* g value (stored as a global array)
    if(first.f == second.f ){
        if(first.g == second.g){
            // If f and g are both the same, sort by lower time 
            return first.timeE > second.timeE; 
        } 
        return first.g < second.g;
    }
    // Otherwise sort by the lower f-value (we reverse this since priority queues usually sort by largest first)
    return (first.f > second.f);
}

/*
 * MEX Function
 */

void mexFunction(int nlhs, mxArray *plhs[ ], int nrhs, const mxArray *prhs[ ]) {
    /* To be called as */
    /* [travel, expanded, solved] = mexWAstar_new(map,childrenI,i,goalI,h,algString) */
    
    /* Check the parameter numbers --------------------------------------------------------------- */
    if ((nrhs != 6) || (nlhs != 3))
        mexErrMsgTxt("should be called as [travel, expanded, solved] = mexWAstar(map,childrenI,i,goalI,h,algString)");
    
    /* Get the input parameters ----------------------------------------------------------------- */
    mxLogical* map = mxGetLogicals(prhs[0]);    
    i64 height = (i64) mxGetM(prhs[0]);
    i64 width = (i64) mxGetN(prhs[0]);
    i64 mapSize = height * width;
    
    i64* frontier = (i64*)mxGetPr(prhs[1]);
    i64 neighSize = mxGetNumberOfElements(prhs[1]);

    i64 stateI = *((i64*) mxGetPr(prhs[2])) - 1;    /* subtract 1 because indexing starts at 0 in C */
    i64 goalI = *((i64*) mxGetPr(prhs[3])) - 1;     /* subtract 1 because indexing starts at 0 in C */
    i64* h = (i64*)mxGetData(prhs[4]);
    
    // Read the algorithm string and algorithm parameters.
    size_t algLen = mxGetN(prhs[5]) + 1;  // Add one for NULL terminator.
    char* algString = (char*) mxMalloc(algLen);
    if (mxGetString(prhs[5], algString, (mwSize)algLen) != 0) {
        mexErrMsgTxt("Error reading algorithm string (use '' and not \"\").");
    }

    /* Create local variables -----------------------------------------------------------------  */

    /* true for elements that are in the closed list */
    mxArray* mxClosed = mxCreateLogicalMatrix((mwSize)height, (mwSize)width);
    mxLogical* closedList = mxGetLogicals(mxClosed);
    
    /* g stores the lowest found g between the state and the root state. The values are valid only for states
     which are in the open or closed list */
    mxArray* mxag = mxCreateNumericMatrix((mwSize)height, (mwSize)width, mxINT64_CLASS, mxREAL);
    i64* g = (i64*) mxGetData(mxag);
    
    /* Prepare necessary data structures */
    i64 n;    
    i64 state2expand;    
    i64 numExpanded = 0;
    i64 traveled;
    bool solved;
    i64 ng;
    i64 i;
    i64 timeExpanded = 0;        
    
    Tree* tree = parse(algString);    
    
    // Construct a priority queue to find the lowest value of f 
    priority_queue<NodeValue> pq;
    
    // Initialize the first state to expand
    g[stateI] = 0;
    double f = tree_priority(tree, h[stateI], g[stateI]);
    NodeValue first(f, g[stateI], stateI, timeExpanded);
    pq.push(first);   

    /* Run the A* loop -----------------------------------------------------------------  */
    while (!pq.empty()) {                
        /* Find the best state by popping from the priority queue */ 
        NodeValue node2expand = pq.top();
        pq.pop();
        state2expand = node2expand.node;
        
        if (node2expand.g != g[state2expand]) {
            // There's a better path to get to this node or we've already expanded it
            continue;
        } else {
            /* Check if the state2expand is the goal */
            if (state2expand == goalI) break;
            
            /* Add it to the closed list */
            closedList[state2expand] = true;
            
            /* Update the number of states expanded */
            numExpanded++;
            
            /* Add its neighbors to the open list */
            for (i=0; i<neighSize; i++) {
                timeExpanded ++; 
                /* Compute a neighbor */
                n = state2expand + frontier[i];
                
                /* Check if it is available (i.e., not a wall or a closed list state) */
                if (map[n] || closedList[n])
                    continue;
                
                /* Compute its (new) g */
                ng = g[state2expand] + 1;    /* all actions cost 1 */
                
                /* Check if the neighbor is on the open list */
                bool is_in_open = g[n] > 0;
                // If either the value we're adding is in the open list with a better value of g
                // Or if the value isn't on the open list, we add it
                if ((is_in_open && ng < g[n]) || !is_in_open){
                        g[n] = ng;
                        f = tree_priority(tree, h[n], ng);
                        NodeValue node2add(f, ng, n, timeExpanded);
                        pq.push(node2add);
                }
            }    
        }
    }
    tree_free(tree);
    
    /* Get the output parameters ------------------------------------------------------------------------ */
    
    /* Compute the number of states in the path */
    if (state2expand != goalI) {
        /* no path was found */
        traveled = -1;
        solved = false;                          
    } else {
        traveled = g[goalI];
        solved = true;
    }
    
    /* Path cost */
    plhs[0] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
    *((i64*) mxGetData(plhs[0])) = traveled;
    
    /* Number of states expanded */
    plhs[1] = mxCreateNumericMatrix(1, 1, mxINT64_CLASS, mxREAL);
    *((i64*) mxGetData(plhs[1])) = numExpanded;
    
    /* Solved */
    plhs[2] = mxCreateLogicalScalar(solved);

    /* Clean up --------------------------------------- */
    mxFree(algString);
    mxDestroyArray(mxClosed);
    mxDestroyArray(mxag);
}

