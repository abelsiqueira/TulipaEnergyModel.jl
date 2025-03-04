minimize
obj: 0.004 flow_(phs,balance),2030,1,1_4_ + 0.002 flow_(phs,balance),2030,1,5_6_ + 0.06 flow_(H2,ccgt),2030,1,1_6_ + 0.01 flow_(wind,balance),2030,1,1_2_ + 0.02 flow_(wind,balance),2030,1,3_6_ + 0.00030000000000000003 flow_(balance,demand),2030,1,1_3_ + 0.00030000000000000003 flow_(balance,demand),2030,1,4_6_ + 0.006 flow_(wind,phs),2030,1,1_3_ + 0.006 flow_(wind,phs),2030,1,4_6_ + 0.05 flow_(ccgt,balance),2030,1,1_1_ + 0.05 flow_(ccgt,balance),2030,1,2_2_ + 0.05 flow_(ccgt,balance),2030,1,3_3_ + 0.05 flow_(ccgt,balance),2030,1,4_4_ + 0.05 flow_(ccgt,balance),2030,1,5_5_ + 0.05 flow_(ccgt,balance),2030,1,6_6_
subject to
max_output_flows_limit_H2,2030,1,1_6_: 1 flow_(H2,ccgt),2030,1,1_6_ <= 400
max_output_flows_limit_ccgt,2030,1,1_1_: 1 flow_(ccgt,balance),2030,1,1_1_ <= 100
max_output_flows_limit_ccgt,2030,1,2_2_: 1 flow_(ccgt,balance),2030,1,2_2_ <= 100
max_output_flows_limit_ccgt,2030,1,3_3_: 1 flow_(ccgt,balance),2030,1,3_3_ <= 100
max_output_flows_limit_ccgt,2030,1,4_4_: 1 flow_(ccgt,balance),2030,1,4_4_ <= 100
max_output_flows_limit_ccgt,2030,1,5_5_: 1 flow_(ccgt,balance),2030,1,5_5_ <= 100
max_output_flows_limit_ccgt,2030,1,6_6_: 1 flow_(ccgt,balance),2030,1,6_6_ <= 100
max_output_flows_limit_phs,2030,1,1_4_: 1 flow_(phs,balance),2030,1,1_4_ <= 25
max_output_flows_limit_phs,2030,1,5_6_: 1 flow_(phs,balance),2030,1,5_6_ <= 25
max_output_flows_limit_wind,2030,1,1_2_: 1 flow_(wind,balance),2030,1,1_2_ + 1 flow_(wind,phs),2030,1,1_3_ <= 11
max_output_flows_limit_wind,2030,1,3_3_: 1 flow_(wind,balance),2030,1,3_6_ + 1 flow_(wind,phs),2030,1,1_3_ <= 11
max_output_flows_limit_wind,2030,1,4_6_: 1 flow_(wind,balance),2030,1,3_6_ + 1 flow_(wind,phs),2030,1,4_6_ <= 10.333333333333334
max_input_flows_limit_phs,2030,1,1_3_: 1 flow_(wind,phs),2030,1,1_3_ <= 25
max_input_flows_limit_phs,2030,1,4_6_: 1 flow_(wind,phs),2030,1,4_6_ <= 25
max_storage_level_rep_period_limit_phs,2030,1,1_6_: 1 storage_level_rep_period_phs,2030,1,1_6_ <= 150
max_transport_flow_limit_(balance,demand),2030,1,1_3_: 1 flow_(balance,demand),2030,1,1_3_ <= 200
max_transport_flow_limit_(balance,demand),2030,1,4_6_: 1 flow_(balance,demand),2030,1,4_6_ <= 200
min_storage_level_rep_period_limit_phs,2030,1,1_6_: 1 storage_level_rep_period_phs,2030,1,1_6_ >= 0
min_transport_flow_limit_(balance,demand),2030,1,1_3_: 1 flow_(balance,demand),2030,1,1_3_ >= -200
min_transport_flow_limit_(balance,demand),2030,1,4_6_: 1 flow_(balance,demand),2030,1,4_6_ >= -200
consumer_balance_demand,2030,1,1_3_: 1 flow_(balance,demand),2030,1,1_3_ = 85
consumer_balance_demand,2030,1,4_6_: 1 flow_(balance,demand),2030,1,4_6_ = 69.99999999999999
balance_storage_rep_period_phs,2030,1,1_6_: 4.444444444444445 flow_(phs,balance),2030,1,1_4_ + 2.2222222222222223 flow_(phs,balance),2030,1,5_6_ - 2.7 flow_(wind,phs),2030,1,1_3_ - 2.7 flow_(wind,phs),2030,1,4_6_ + 1 storage_level_rep_period_phs,2030,1,1_6_ = 0
balance_hub_balance,2030,1,1_1_: 1 flow_(phs,balance),2030,1,1_4_ + 1 flow_(wind,balance),2030,1,1_2_ - 1 flow_(balance,demand),2030,1,1_3_ + 1 flow_(ccgt,balance),2030,1,1_1_ = 0
balance_hub_balance,2030,1,2_2_: 1 flow_(phs,balance),2030,1,1_4_ + 1 flow_(wind,balance),2030,1,1_2_ - 1 flow_(balance,demand),2030,1,1_3_ + 1 flow_(ccgt,balance),2030,1,2_2_ = 0
balance_hub_balance,2030,1,3_3_: 1 flow_(phs,balance),2030,1,1_4_ + 1 flow_(wind,balance),2030,1,3_6_ - 1 flow_(balance,demand),2030,1,1_3_ + 1 flow_(ccgt,balance),2030,1,3_3_ = 0
balance_hub_balance,2030,1,4_4_: 1 flow_(phs,balance),2030,1,1_4_ + 1 flow_(wind,balance),2030,1,3_6_ - 1 flow_(balance,demand),2030,1,4_6_ + 1 flow_(ccgt,balance),2030,1,4_4_ = 0
balance_hub_balance,2030,1,5_5_: 1 flow_(phs,balance),2030,1,5_6_ + 1 flow_(wind,balance),2030,1,3_6_ - 1 flow_(balance,demand),2030,1,4_6_ + 1 flow_(ccgt,balance),2030,1,5_5_ = 0
balance_hub_balance,2030,1,6_6_: 1 flow_(phs,balance),2030,1,5_6_ + 1 flow_(wind,balance),2030,1,3_6_ - 1 flow_(balance,demand),2030,1,4_6_ + 1 flow_(ccgt,balance),2030,1,6_6_ = 0
conversion_balance_ccgt,2030,1,1_6_: 6 flow_(H2,ccgt),2030,1,1_6_ - 2 flow_(ccgt,balance),2030,1,1_1_ - 2 flow_(ccgt,balance),2030,1,2_2_ - 2 flow_(ccgt,balance),2030,1,3_3_ - 2 flow_(ccgt,balance),2030,1,4_4_ - 2 flow_(ccgt,balance),2030,1,5_5_ - 2 flow_(ccgt,balance),2030,1,6_6_ = 0
Bounds
flow_(phs,balance),2030,1,1_4_ >= 0
flow_(phs,balance),2030,1,5_6_ >= 0
flow_(H2,ccgt),2030,1,1_6_ >= 0
flow_(wind,balance),2030,1,1_2_ >= 0
flow_(wind,balance),2030,1,3_6_ >= 0
flow_(balance,demand),2030,1,1_3_ free
flow_(balance,demand),2030,1,4_6_ free
flow_(wind,phs),2030,1,1_3_ >= 0
flow_(wind,phs),2030,1,4_6_ >= 0
flow_(ccgt,balance),2030,1,1_1_ >= 0
flow_(ccgt,balance),2030,1,2_2_ >= 0
flow_(ccgt,balance),2030,1,3_3_ >= 0
flow_(ccgt,balance),2030,1,4_4_ >= 0
flow_(ccgt,balance),2030,1,5_5_ >= 0
flow_(ccgt,balance),2030,1,6_6_ >= 0
storage_level_rep_period_phs,2030,1,1_6_ >= 0
End
