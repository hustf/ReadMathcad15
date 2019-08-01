# ReadMathcad15



## Usage
```
julia > ]add ReadMathcad15

julia> cd("../../dev\\ReadMathcad15\\test\\")

julia> fnam = "testfile.xmcd"

julia> print_symbols_from(fnam)
ϕ_pb          ϕ_tj          l_s           δ_fabr_arc               δ_tj          δ_pb          d_pb          d_tj                     w_g           d_c           r_range       r_i                      r_o           b             Δ             F_contact                L_f           A_c_r         A_c_t         W_c_r                    W_c_t         I_r           I_t           I_sp                     u_FE_s_p      σ_FE_r        u_FE_r1       u_FE_r2                  σ_FE_r2       E_FE          q_s_a_t       q_s_a_l                  q_s_w         a_ex          a_ey          F_y                      F_x           y_tie         c_bu          c_st_t                   c_st_b        c_tie         F_x           u_F1                     u_max_F1      M_F1_r        σ_F1_r        U_F1_r                   M_F1_t        σ_F1_t        U_F1_t        M_F3_r                   σ_F3_r        U_F3_r        M_F3_t        σ_F3_t                   U_F3_t        F_max_tie     θ_max_tie     F_x_cr                   F_y_cr        κ_y_pry_crit  M_F2_r        σ_F2_r                   U_F2_r        M_F2_t        σ_F2_t        U_F2_t

julia> @assign fnam ϕ_pb          ϕ_tj          l_s           δ_fabr_arc               δ_tj          δ_pb

        ϕ_pb = 168.27499999999998mm
        ϕ_tj = 215.89999999999998mm
        l_s = 126.5ft
        δ_fabr_arc = [1.8499999999999999; 0.0]mm
        δ_tj = [0.07873999999999999; -0.07873999999999999]mm
        δ_pb = [1.6827499999999997; -0.8413749999999999]mm

```
