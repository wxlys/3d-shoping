<template>
  <div class="print-queue-page">
    <el-row :gutter="16" class="summary-row">
      <el-col :xs="12" :sm="6" v-for="item in summaryItems" :key="item.key">
        <el-card shadow="never" class="summary-card">
          <div class="summary-label">{{ item.label }}</div>
          <div class="summary-value" :class="item.className">{{ summary[item.key] || 0 }}</div>
        </el-card>
      </el-col>
    </el-row>

    <el-card :bordered="false" shadow="never" class="ivu-mt" :body-style="{ padding: 0 }">
      <div class="padding-add">
        <el-form :model="query" inline @submit.native.prevent>
          <el-form-item label="状态：">
            <el-select v-model="query.status" clearable placeholder="全部状态" style="width: 130px">
              <el-option :value="1" label="排队中" />
              <el-option :value="2" label="制作中" />
              <el-option :value="3" label="已完成" />
              <el-option :value="4" label="已取消" />
            </el-select>
          </el-form-item>
          <el-form-item label="订单号：">
            <el-input v-model="query.order_id" clearable placeholder="请输入订单号" @keyup.enter.native="search" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" v-db-click @click="search">查询</el-button>
            <el-button v-db-click @click="reset">重置</el-button>
          </el-form-item>
        </el-form>
      </div>
    </el-card>

    <el-card :bordered="false" shadow="never" class="ivu-mt">
      <el-table :data="list" v-loading="loading" highlight-current-row>
        <el-table-column label="排位" width="70" prop="queue_no" />
        <el-table-column label="订单号" min-width="170" prop="order_id" />
        <el-table-column label="用户" min-width="130">
          <template slot-scope="scope">{{ scope.row.nickname || scope.row.uid }}（{{ scope.row.uid }}）</template>
        </el-table-column>
        <el-table-column label="模型文件" min-width="170" prop="filename" show-overflow-tooltip />
        <el-table-column label="规格" min-width="130">
          <template slot-scope="scope">{{ scope.row.size_level }} / {{ scope.row.material }} × {{ scope.row.total_num }}</template>
        </el-table-column>
        <el-table-column label="预计开始" min-width="160" prop="expected_start_at_text" />
        <el-table-column label="预计交付" min-width="160" prop="expected_end_at_text" />
        <el-table-column label="状态" width="100">
          <template slot-scope="scope">
            <el-tag size="mini" :type="statusTag(scope.row.status)">{{ scope.row.status_name }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="进度备注" min-width="170" prop="progress_note" show-overflow-tooltip />
        <el-table-column label="操作" fixed="right" width="250">
          <template slot-scope="scope">
            <el-button v-if="scope.row.status === 1" type="text" v-db-click @click="start(scope.row)">开始打印</el-button>
            <el-button v-if="scope.row.status === 2" type="text" v-db-click @click="complete(scope.row)">打印完成</el-button>
            <el-button v-if="scope.row.status === 1" type="text" v-db-click @click="openSchedule(scope.row)">调整排期</el-button>
            <el-button v-if="scope.row.status === 1 || scope.row.status === 2" type="text" v-db-click @click="openProgress(scope.row)">进度备注</el-button>
          </template>
        </el-table-column>
      </el-table>
      <div class="acea-row row-right page">
        <pagination v-if="total" :total="total" :page.sync="query.page" :limit.sync="query.limit" @pagination="getList" />
      </div>
    </el-card>

    <el-dialog :visible.sync="scheduleVisible" title="调整排期" width="460px">
      <el-form label-width="100px" @submit.native.prevent>
        <el-form-item label="订单号：">{{ currentRow.order_id }}</el-form-item>
        <el-form-item label="预计开始：">
          <el-date-picker v-model="scheduleForm.expected_start_at" type="datetime" value-format="timestamp" format="yyyy-MM-dd HH:mm" placeholder="选择开始时间" style="width: 260px" />
        </el-form-item>
        <el-form-item label="预计交付：">
          <el-date-picker v-model="scheduleForm.expected_deliver_at" type="datetime" value-format="timestamp" format="yyyy-MM-dd HH:mm" placeholder="选择交付时间" style="width: 260px" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="scheduleVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" v-db-click @click="saveSchedule">保存</el-button>
      </div>
    </el-dialog>

    <el-dialog :visible.sync="progressVisible" title="更新进度备注" width="520px">
      <el-form label-width="100px" @submit.native.prevent>
        <el-form-item label="订单号：">{{ currentRow.order_id }}</el-form-item>
        <el-form-item label="进度备注：">
          <el-input v-model="progressForm.progress_note" type="textarea" :rows="4" maxlength="500" show-word-limit placeholder="例如：已完成外壳打印，正在打磨" />
        </el-form-item>
      </el-form>
      <div slot="footer">
        <el-button @click="progressVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" v-db-click @click="saveProgress">保存</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import {
  printQueueAdjust,
  printQueueComplete,
  printQueueList,
  printQueueProgress,
  printQueueStart,
} from '@/api/print';

export default {
  name: 'PrintQueue',
  data() {
    return {
      loading: false,
      saving: false,
      total: 0,
      list: [],
      summary: {},
      query: {
        page: 1,
        limit: 20,
        status: '',
        order_id: '',
      },
      currentRow: {},
      scheduleVisible: false,
      progressVisible: false,
      scheduleForm: { expected_start_at: '', expected_deliver_at: '' },
      progressForm: { progress_note: '' },
      summaryItems: [
        { key: 1, label: '排队中', className: 'warning' },
        { key: 2, label: '制作中', className: 'primary' },
        { key: 3, label: '已完成', className: 'success' },
        { key: 4, label: '已取消', className: 'muted' },
      ],
    };
  },
  created() {
    this.getList();
  },
  methods: {
    getList() {
      this.loading = true;
      printQueueList(this.query)
        .then((res) => {
          const data = res.data || {};
          this.list = data.list || [];
          this.total = Number(data.count || 0);
          this.summary = data.summary || {};
        })
        .catch((err) => this.$message.error(err.msg || err.message || '排单列表加载失败'))
        .finally(() => {
          this.loading = false;
        });
    },
    search() {
      this.query.page = 1;
      this.getList();
    },
    reset() {
      this.query.status = '';
      this.query.order_id = '';
      this.search();
    },
    statusTag(status) {
      return { 1: 'warning', 2: '', 3: 'success', 4: 'info' }[status] || 'info';
    },
    start(row) {
      this.$confirm(`确认开始订单 ${row.order_id} 的打印吗？`, '提示', { type: 'warning' })
        .then(() => printQueueStart({ order_id: row.order_db_id }))
        .then(() => {
          this.$message.success('已开始打印');
          this.getList();
        })
        .catch((err) => {
          if (err !== 'cancel' && err !== 'close') this.$message.error(err.msg || err.message || '操作失败');
        });
    },
    complete(row) {
      this.$confirm(`确认订单 ${row.order_id} 已打印完成吗？`, '提示', { type: 'warning' })
        .then(() => printQueueComplete({ order_id: row.order_db_id }))
        .then(() => {
          this.$message.success('打印完成');
          this.getList();
        })
        .catch((err) => {
          if (err !== 'cancel' && err !== 'close') this.$message.error(err.msg || err.message || '操作失败');
        });
    },
    openSchedule(row) {
      this.currentRow = row;
      this.scheduleForm.expected_start_at = row.expected_start_at ? Number(row.expected_start_at) * 1000 : Date.now() + 3600000;
      this.scheduleForm.expected_deliver_at = row.expected_end_at
        ? Number(row.expected_end_at) * 1000
        : this.scheduleForm.expected_start_at + 86400000;
      this.scheduleVisible = true;
    },
    saveSchedule() {
      const startTimestamp = Number(this.scheduleForm.expected_start_at || 0) / 1000;
      const deliverTimestamp = Number(this.scheduleForm.expected_deliver_at || 0) / 1000;
      if (!startTimestamp || startTimestamp <= Date.now() / 1000) {
        this.$message.warning('排期时间必须晚于当前时间');
        return;
      }
      if (!deliverTimestamp || deliverTimestamp <= startTimestamp) {
        this.$message.warning('预计交付时间必须晚于预计开始时间');
        return;
      }
      this.saving = true;
      printQueueAdjust({
        order_id: this.currentRow.order_db_id,
        expected_start_at: Math.floor(startTimestamp),
        expected_deliver_at: Math.floor(deliverTimestamp),
      })
        .then(() => {
          this.$message.success('排期已调整');
          this.scheduleVisible = false;
          this.getList();
        })
        .catch((err) => this.$message.error(err.msg || err.message || '排期调整失败'))
        .finally(() => {
          this.saving = false;
        });
    },
    openProgress(row) {
      this.currentRow = row;
      this.progressForm.progress_note = row.progress_note || '';
      this.progressVisible = true;
    },
    saveProgress() {
      this.saving = true;
      printQueueProgress({ order_id: this.currentRow.order_db_id, progress_note: this.progressForm.progress_note })
        .then(() => {
          this.$message.success('进度备注已更新');
          this.progressVisible = false;
          this.getList();
        })
        .catch((err) => this.$message.error(err.msg || err.message || '进度更新失败'))
        .finally(() => {
          this.saving = false;
        });
    },
  },
};
</script>

<style lang="scss" scoped>
.summary-row {
  margin-bottom: 16px;
}

.summary-card {
  text-align: center;
}

.summary-label {
  color: #909399;
  font-size: 13px;
}

.summary-value {
  margin-top: 8px;
  font-size: 28px;
  font-weight: 600;

  &.warning { color: #e6a23c; }
  &.primary { color: #409eff; }
  &.success { color: #67c23a; }
  &.muted { color: #909399; }
}

.page {
  padding-top: 16px;
}
</style>
